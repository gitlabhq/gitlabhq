# frozen_string_literal: true

require 'active_support/inflector'

module QA
  module Service
    module ClusterProvider
      class Gcloud < Base
        def validate_dependencies
          find_executable('gcloud') || raise("You must first install `gcloud` executable to run these tests.")
        end

        def initialize(rbac:)
          super(rbac: rbac)
          @attempts = 0
          @available_regions = %w[
            asia-east1 asia-east2
            asia-northeast1 asia-south1
            asia-southeast1 australia-southeast1
            europe-west1 europe-west2 europe-west4
            northamerica-northeast1 southamerica-east1
            us-central1 us-east1 us-east4
            us-west1 us-west2
          ]
        end

        def setup
          login_if_not_already_logged_in
          create_cluster
        end

        def teardown
          delete_cluster
        end

        def connect
          login_if_not_already_logged_in

          shell <<~CMD.tr("\n", ' ')
            gcloud container clusters get-credentials
              --region #{Runtime::Env.workspaces_cluster_region}
              #{Runtime::Env.workspaces_cluster_name}
          CMD
        end

        def install_kubernetes_agent(agent_token:, kas_address:, agent_name: "gitlab-agent")
          cmd_str = <<~CMD.tr("\n", ' ')
            helm repo add gitlab https://charts.gitlab.io &&
            helm repo update &&
            helm upgrade --install gitlab-agent gitlab/gitlab-agent
              --namespace "#{agent_name}"
              --create-namespace
              --set config.token=#{agent_token}
              --set config.kasAddress=#{kas_address}
              --set config.kasHeaders="{Cookie: gitlab_canary=#{target_canary?}}"
              --set replicas=1
          CMD
          shell(cmd_str, mask_secrets: [agent_token])
        end

        def uninstall_kubernetes_agent(agent_name: "gitlab-agent")
          shell <<~CMD.tr("\n", ' ')
            helm uninstall gitlab-agent \
              --namespace "#{agent_name}"
          CMD
        end

        def install_ngnix_ingress
          shell <<~CMD.tr("\n", ' ')
            helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx &&
            helm repo update &&
            helm install \
              ingress-nginx ingress-nginx/ingress-nginx \
              --namespace ingress-nginx \
              --create-namespace \
              --version 4.3.0
          CMD
        end

        def wait_for_pod(namespace)
          shell <<~CMD.tr("\n", ' ')
            kubectl wait pod \
              --all \
              --for=condition=Ready \
              --namespace=#{namespace} \
              --timeout=300s
          CMD
        end

        def install_gitlab_workspaces_proxy
          cmd_str = <<~CMD.tr("\n", ' ')
            helm repo add gitlab-workspaces-proxy \
              https://gitlab.com/api/v4/projects/gitlab-org%2fremote-development%2fgitlab-workspaces-proxy/packages/helm/devel &&
            helm repo update &&
            helm upgrade --install gitlab-workspaces-proxy \
              gitlab-workspaces-proxy/gitlab-workspaces-proxy \
              --version #{Runtime::Env.workspaces_proxy_version} \
              --namespace=gitlab-workspaces \
              --create-namespace \
              --set="auth.client_id=#{Runtime::Env.workspaces_oauth_app_id}" \
              --set="auth.client_secret=#{Runtime::Env.workspaces_oauth_app_secret}" \
              --set="auth.host=#{Runtime::Env.gitlab_url}" \
              --set="auth.redirect_uri=https://#{Runtime::Env.workspaces_proxy_domain}/auth/callback" \
              --set="auth.signing_key=#{Runtime::Env.workspaces_oauth_signing_key}" \
              --set="ingress.host.workspaceDomain=#{Runtime::Env.workspaces_proxy_domain}" \
              --set="ingress.host.wildcardDomain=*.#{Runtime::Env.workspaces_proxy_domain}" \
              --set="ingress.tls.workspaceDomainCert=$(echo $WORKSPACES_DOMAIN_CERT)" \
              --set="ingress.tls.workspaceDomainKey=$(echo $WORKSPACES_DOMAIN_KEY)" \
              --set="ingress.tls.wildcardDomainCert=$(echo $WORKSPACES_WILDCARD_CERT)" \
              --set="ingress.tls.wildcardDomainKey=$(echo $WORKSPACES_WILDCARD_KEY)" \
              --set="ingress.className=nginx"
          CMD

          shell(cmd_str, mask_secrets: [Runtime::Env.workspaces_oauth_app_secret, Runtime::Env.workspaces_oauth_signing_key, Runtime::Env.workspaces_domain_cert, Runtime::Env.workspaces_domain_key, Runtime::Env.workspaces_wildcard_cert, Runtime::Env.workspaces_wildcard_key])
        end

        def update_dns(load_balancer_ip)
          shell <<~CMD.tr("\n", ' ')
            gcloud dns record-sets update #{Runtime::Env.workspaces_proxy_domain} \
            --rrdatas=#{load_balancer_ip} \
            --ttl=300 \
            --type=A \
            --zone=gitlabqa-dev
          CMD

          shell <<~CMD.tr("\n", ' ')
            gcloud dns record-sets update "*.#{Runtime::Env.workspaces_proxy_domain}" \
            --rrdatas=#{load_balancer_ip} \
            --ttl=300 \
            --type=A \
            --zone=gitlabqa-dev
          CMD
        end

        private

        def target_canary?
          Runtime::Env.qa_cookies.to_s.include?("gitlab_canary=true")
        end

        def login_if_not_already_logged_in
          if Runtime::Env.has_gcloud_credentials?
            attempt_login_with_env_vars
          else
            account = `gcloud auth list --filter=status:ACTIVE --format="value(account)"`
            if account.empty?
              raise "Failed to login to gcloud. No credentials provided in environment and no credentials found locally."
            else
              QA::Runtime::Logger.debug("gcloud account found. Using: #{account} for creating K8s cluster.")
            end
          end
        end

        def attempt_login_with_env_vars
          QA::Runtime::Logger.debug("Logging in with GCLOUD_ACCOUNT_EMAIL and GCLOUD_ACCOUNT_KEY.")
          gcloud_account_key = Tempfile.new('gcloud-account-key')
          gcloud_account_key.write(Runtime::Env.gcloud_account_key)
          gcloud_account_key.close
          gcloud_account_email = Runtime::Env.gcloud_account_email
          shell("gcloud auth activate-service-account #{gcloud_account_email} --key-file #{gcloud_account_key.path}")
        ensure
          gcloud_account_key && gcloud_account_key.unlink
        end

        def auth_options
          "--enable-legacy-authorization" unless rbac
        end

        def create_cluster
          @region = get_region

          shell <<~CMD.tr("\n", ' ')
            gcloud container clusters
            create #{cluster_name}
            #{auth_options}
            --region #{@region}
            --disk-size 15GB
            --num-nodes #{Runtime::Env.gcloud_num_nodes}
            && gcloud container clusters
            get-credentials
            --region #{@region}
            #{cluster_name}
          CMD
        rescue QA::Service::Shellout::CommandError
          @attempts += 1

          retry unless @attempts > 1

          raise $!, "Tried and failed to provision the cluster #{@attempts} #{'time'.pluralize(@attempts)}.", $!.backtrace
        end

        def delete_cluster
          shell <<~CMD.tr("\n", ' ')
            gcloud container clusters delete
              --region #{@region}
              #{cluster_name}
              --quiet --async
          CMD
        end

        def get_region
          Runtime::Env.gcloud_region || @available_regions.delete(@available_regions.sample)
        end
      end
    end
  end
end

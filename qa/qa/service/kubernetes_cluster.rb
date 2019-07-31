# frozen_string_literal: true

require 'securerandom'
require 'mkmf'
require 'pathname'

module QA
  module Service
    class KubernetesCluster
      include Service::Shellout

      attr_reader :api_url, :ca_certificate, :token, :rbac

      def initialize(rbac: true)
        @rbac = rbac
      end

      def cluster_name
        @cluster_name ||= "qa-cluster-#{SecureRandom.hex(4)}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
      end

      def create!
        validate_dependencies
        login_if_not_already_logged_in

        shell <<~CMD.tr("\n", ' ')
          gcloud container clusters
          create #{cluster_name}
          #{auth_options}
          --enable-basic-auth
          --region #{Runtime::Env.gcloud_region}
          --disk-size 10GB
          --num-nodes #{Runtime::Env.gcloud_num_nodes}
          && gcloud container clusters
          get-credentials
          --region #{Runtime::Env.gcloud_region}
          #{cluster_name}
        CMD

        @api_url = `kubectl config view --minify -o jsonpath='{.clusters[].cluster.server}'`

        @admin_user = "#{cluster_name}-admin"
        master_auth = JSON.parse(`gcloud container clusters describe #{cluster_name} --region #{Runtime::Env.gcloud_region} --format 'json(masterAuth.username, masterAuth.password)'`)
        shell <<~CMD.tr("\n", ' ')
          kubectl config set-credentials #{@admin_user}
          --username #{master_auth['masterAuth']['username']}
          --password #{master_auth['masterAuth']['password']}
        CMD

        if rbac
          create_service_account

          secrets = JSON.parse(`kubectl get secrets -o json`)
          gitlab_account = secrets['items'].find do |item|
            item['metadata']['annotations']['kubernetes.io/service-account.name'] == 'gitlab-account'
          end

          @ca_certificate = Base64.decode64(gitlab_account['data']['ca.crt'])
          @token = Base64.decode64(gitlab_account['data']['token'])
        else
          @ca_certificate = Base64.decode64(`kubectl get secrets -o jsonpath="{.items[0].data['ca\\.crt']}"`)
          @token = Base64.decode64(`kubectl get secrets -o jsonpath='{.items[0].data.token}'`)
        end

        self
      end

      def remove!
        shell <<~CMD.tr("\n", ' ')
          gcloud container clusters delete
          --region #{Runtime::Env.gcloud_region}
          #{cluster_name}
          --quiet --async
        CMD
      end

      private

      def create_service_account
        shell('kubectl create -f -', stdin_data: service_account)
        shell("kubectl --user #{@admin_user} create -f -", stdin_data: service_account_role_binding)
      end

      def service_account
        <<~YAML
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            name: gitlab-account
            namespace: default
        YAML
      end

      def service_account_role_binding
        <<~YAML
          kind: ClusterRoleBinding
          apiVersion: rbac.authorization.k8s.io/v1
          metadata:
            name: gitlab-account-binding
          subjects:
          - kind: ServiceAccount
            name: gitlab-account
            namespace: default
          roleRef:
            kind: ClusterRole
            name: cluster-admin
            apiGroup: rbac.authorization.k8s.io
        YAML
      end

      def auth_options
        "--enable-legacy-authorization" unless rbac
      end

      def validate_dependencies
        find_executable('gcloud') || raise("You must first install `gcloud` executable to run these tests.")
        find_executable('kubectl') || raise("You must first install `kubectl` executable to run these tests.")
      end

      def login_if_not_already_logged_in
        if Runtime::Env.has_gcloud_credentials?
          attempt_login_with_env_vars
        else
          account = `gcloud auth list --filter=status:ACTIVE --format="value(account)"`
          if account.empty?
            raise "Failed to login to gcloud. No credentials provided in environment and no credentials found locally."
          else
            puts "gcloud account found. Using: #{account} for creating K8s cluster."
          end
        end
      end

      def attempt_login_with_env_vars
        puts "No gcloud account. Attempting to login from env vars GCLOUD_ACCOUNT_EMAIL and GCLOUD_ACCOUNT_KEY."
        gcloud_account_key = Tempfile.new('gcloud-account-key')
        gcloud_account_key.write(Runtime::Env.gcloud_account_key)
        gcloud_account_key.close
        gcloud_account_email = Runtime::Env.gcloud_account_email
        shell("gcloud auth activate-service-account #{gcloud_account_email} --key-file #{gcloud_account_key.path}")
      ensure
        gcloud_account_key && gcloud_account_key.unlink
      end
    end
  end
end

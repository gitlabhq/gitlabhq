# frozen_string_literal: true

module QA
  module Service
    module ClusterProvider
      class Gcloud < Base
        def validate_dependencies
          find_executable('gcloud') || raise("You must first install `gcloud` executable to run these tests.")
        end

        def set_credentials(admin_user)
          master_auth = JSON.parse(`gcloud container clusters describe #{cluster_name} --region #{Runtime::Env.gcloud_region} --format 'json(masterAuth.username, masterAuth.password)'`)

          shell <<~CMD.tr("\n", ' ')
            kubectl config set-credentials #{admin_user}
              --username #{master_auth['masterAuth']['username']}
              --password #{master_auth['masterAuth']['password']}
          CMD
        end

        def setup
          login_if_not_already_logged_in
          create_cluster
        end

        def teardown
          delete_cluster
        end

        private

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

        def auth_options
          "--enable-legacy-authorization" unless rbac
        end

        def create_cluster
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
        end

        def delete_cluster
          shell <<~CMD.tr("\n", ' ')
            gcloud container clusters delete
              --region #{Runtime::Env.gcloud_region}
              #{cluster_name}
              --quiet --async
          CMD
        end
      end
    end
  end
end

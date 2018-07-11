require 'securerandom'
require 'mkmf'

module QA
  module Service
    class KubernetesCluster
      include Service::Shellout

      attr_reader :api_url, :ca_certificate, :token

      def cluster_name
        @cluster_name ||= "qa-cluster-#{SecureRandom.hex(4)}-#{Time.now.utc.strftime("%Y%m%d%H%M%S")}"
      end

      def create!
        validate_dependencies
        login_if_not_already_logged_in

        shell <<~CMD.tr("\n", ' ')
          gcloud container clusters
          create #{cluster_name}
          --enable-legacy-authorization
          --zone #{Runtime::Env.gcloud_zone}
          && gcloud container clusters
          get-credentials
          --zone #{Runtime::Env.gcloud_zone}
          #{cluster_name}
        CMD

        @api_url = `kubectl config view --minify -o jsonpath='{.clusters[].cluster.server}'`
        @ca_certificate = Base64.decode64(`kubectl get secrets -o jsonpath="{.items[0].data['ca\\.crt']}"`)
        @token = Base64.decode64(`kubectl get secrets -o jsonpath='{.items[0].data.token}'`)
        self
      end

      def remove!
        shell <<~CMD.tr("\n", ' ')
          gcloud container clusters delete
          --zone #{Runtime::Env.gcloud_zone}
	  #{cluster_name}
	  --quiet --async
	CMD
      end

      private

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

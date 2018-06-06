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
          --zone us-central1-a
          && gcloud container clusters
          get-credentials #{cluster_name}
        CMD

        @api_url = `kubectl config view --minify -o jsonpath='{.clusters[].cluster.server}'`
        @ca_certificate = Base64.decode64(`kubectl get secrets -o jsonpath="{.items[0].data['ca\\.crt']}"`)
        @token = Base64.decode64(`kubectl get secrets -o jsonpath='{.items[0].data.token}'`)
        self
      end

      def remove!
        shell("gcloud container clusters delete #{cluster_name} --quiet --async")
      end

      private

      def validate_dependencies
        find_executable('gcloud') || raise("You must first install `gcloud` executable to run these tests.")
        find_executable('kubectl') || raise("You must first install `kubectl` executable to run these tests.")
      end

      def login_if_not_already_logged_in
        account = `gcloud auth list --filter=status:ACTIVE --format="value(account)"`
        if account.empty?
          attempt_login_with_env_vars
        else
          puts "gcloud account found. Using: #{account} for creating K8s cluster."
        end
      end

      def attempt_login_with_env_vars
        puts "No gcloud account. Attempting to login from env vars GCLOUD_ACCOUNT_EMAIL and GCLOUD_ACCOUNT_KEY."
        gcloud_account_key = Tempfile.new('gcloud-account-key')
        gcloud_account_key.write(ENV.fetch("GCLOUD_ACCOUNT_KEY"))
        gcloud_account_key.close
        gcloud_account_email = ENV.fetch("GCLOUD_ACCOUNT_EMAIL")
        shell("gcloud auth activate-service-account #{gcloud_account_email} --key-file #{gcloud_account_key.path}")
      ensure
        gcloud_account_key && gcloud_account_key.unlink
      end
    end
  end
end

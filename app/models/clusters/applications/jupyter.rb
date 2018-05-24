module Clusters
  module Applications
    class Jupyter < ActiveRecord::Base
      VERSION = '0.0.1'.freeze

      self.table_name = 'clusters_applications_jupyters'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationData

      belongs_to :oauth_application, class_name: 'Doorkeeper::Application'

      default_value_for :version, VERSION

      def chart
        "#{name}/jupyterhub"
      end

      def repository
        'https://jupyterhub.github.io/helm-chart/'
      end

      def values
        content_values.to_yaml
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name,
          chart: chart,
          values: values,
          repository: repository
        )
      end

      def callback_url
        "http://#{hostname}/hub/oauth_callback"
      end

      private

      def specification
        {
          "ingress" => {
            "hosts" => [hostname]
          },
          "hub" => {
            "extraEnv" => {
              "GITLAB_HOST" => gitlab_url
            },
            "cookieSecret" => SecureRandom.hex(32)
          },
          "proxy" => {
            "secretToken" => SecureRandom.hex(32)
          },
          "auth" => {
            "gitlab" => {
              "clientId" => oauth_application.uid,
              "clientSecret" => oauth_application.secret,
              "callbackUrl" => callback_url
            }
          }
        }
      end

      def gitlab_url
        Gitlab.config.gitlab.url
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end
    end
  end
end

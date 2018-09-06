# frozen_string_literal: true

module Clusters
  module Applications
    class Jupyter < ActiveRecord::Base
      VERSION = 'v0.6'.freeze

      self.table_name = 'clusters_applications_jupyter'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      belongs_to :oauth_application, class_name: 'Doorkeeper::Application'

      default_value_for :version, VERSION

      def set_initial_status
        return unless not_installable?

        if cluster&.application_ingress_installed? && cluster.application_ingress.external_ip
          self.status = 'installable'
        end
      end

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
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
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
            "cookieSecret" => cookie_secret
          },
          "proxy" => {
            "secretToken" => secret_token
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

      def secret_token
        @secret_token ||= SecureRandom.hex(32)
      end

      def cookie_secret
        @cookie_secret ||= SecureRandom.hex(32)
      end
    end
  end
end

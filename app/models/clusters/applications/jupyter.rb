# frozen_string_literal: true

require 'securerandom'

module Clusters
  module Applications
    # DEPRECATED for removal in %14.0
    # See https://gitlab.com/groups/gitlab-org/-/epics/4280
    class Jupyter < ApplicationRecord
      VERSION = '0.9.0'

      self.table_name = 'clusters_applications_jupyter'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      belongs_to :oauth_application, class_name: 'Doorkeeper::Application'

      default_value_for :version, VERSION

      def set_initial_status
        return unless not_installable?
        return unless cluster&.application_ingress_available?

        ingress = cluster.application_ingress
        self.status = status_states[:installable] if ingress.external_ip_or_hostname?
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
        helm_command_module::InstallCommand.new(
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

      def oauth_scopes
        'api read_repository write_repository'
      end

      private

      def specification
        {
          "ingress" => {
            "hosts" => [hostname],
            "tls" => [{
              "hosts" => [hostname],
              "secretName" => "jupyter-cert"
            }]
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
            "state" => {
              "cryptoKey" => crypto_key
            },
            "gitlab" => {
              "clientId" => oauth_application.uid,
              "clientSecret" => oauth_application.secret,
              "callbackUrl" => callback_url,
              "gitlabProjectIdWhitelist" => cluster.projects.ids,
              "gitlabGroupWhitelist" => cluster.groups.map(&:to_param)
            }
          },
          "singleuser" => {
            "extraEnv" => {
              "GITLAB_CLUSTER_ID" => cluster.id.to_s,
              "GITLAB_HOST" => gitlab_host
            }
          }
        }
      end

      def crypto_key
        @crypto_key ||= SecureRandom.hex(32)
      end

      def gitlab_url
        Gitlab.config.gitlab.url
      end

      def gitlab_host
        Gitlab.config.gitlab.host
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

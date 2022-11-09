# frozen_string_literal: true

module Clusters
  module Applications
    class Runner < ApplicationRecord
      VERSION = '0.42.1'

      self.table_name = 'clusters_applications_runners'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      belongs_to :runner, class_name: 'Ci::Runner', foreign_key: :runner_id
      delegate :project, :group, to: :cluster

      attribute :version, default: VERSION

      def chart
        "#{name}/gitlab-runner"
      end

      def repository
        'https://charts.gitlab.io'
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

      def prepare_uninstall
        # No op, see https://gitlab.com/gitlab-org/gitlab/-/issues/350180.
      end

      def post_uninstall
        runner.destroy!
      end

      private

      def gitlab_url
        Gitlab::Routing.url_helpers.root_url(only_path: false)
      end

      def specification
        {
          "gitlabUrl" => gitlab_url,
          "runners" => { "privileged" => privileged }
        }
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end
    end
  end
end

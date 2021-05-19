# frozen_string_literal: true

module Clusters
  module Applications
    class ElasticStack < ApplicationRecord
      include ::Clusters::Concerns::ElasticsearchClient

      VERSION = '3.0.0'

      self.table_name = 'clusters_applications_elastic_stacks'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      after_destroy do
        cluster&.find_or_build_integration_elastic_stack&.update(enabled: false, chart_version: nil)
      end

      state_machine :status do
        after_transition any => [:installed] do |application|
          application.cluster&.find_or_build_integration_elastic_stack&.update(enabled: true, chart_version: application.version)
        end

        after_transition any => [:uninstalled] do |application|
          application.cluster&.find_or_build_integration_elastic_stack&.update(enabled: false, chart_version: nil)
        end
      end

      def chart
        'elastic-stack/elastic-stack'
      end

      def repository
        'https://charts.gitlab.io'
      end

      def install_command
        helm_command_module::InstallCommand.new(
          name: 'elastic-stack',
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          repository: repository,
          files: files,
          preinstall: migrate_to_3_script,
          postinstall: post_install_script
        )
      end

      def uninstall_command
        helm_command_module::DeleteCommand.new(
          name: 'elastic-stack',
          rbac: cluster.platform_kubernetes_rbac?,
          files: files,
          postdelete: post_delete_script
        )
      end

      def files
        super.merge('wait-for-elasticsearch.sh': File.read("#{Rails.root}/vendor/elastic_stack/wait-for-elasticsearch.sh"))
      end

      def chart_above_v2?
        Gem::Version.new(version) >= Gem::Version.new('2.0.0')
      end

      def chart_above_v3?
        Gem::Version.new(version) >= Gem::Version.new('3.0.0')
      end

      private

      def service_name
        chart_above_v3? ? 'elastic-stack-elasticsearch-master' : 'elastic-stack-elasticsearch-client'
      end

      def pvc_selector
        chart_above_v3? ? "app=elastic-stack-elasticsearch-master" : "release=elastic-stack"
      end

      def post_install_script
        [
          "timeout 60 sh /data/helm/elastic-stack/config/wait-for-elasticsearch.sh http://elastic-stack-elasticsearch-master:9200"
        ]
      end

      def post_delete_script
        [
          Gitlab::Kubernetes::KubectlCmd.delete("pvc", "--selector", pvc_selector, "--namespace", Gitlab::Kubernetes::Helm::NAMESPACE)
        ]
      end

      def migrate_to_3_script
        return [] if !updating? || chart_above_v3?

        # Chart version 3.0.0 moves to our own chart at https://gitlab.com/gitlab-org/charts/elastic-stack
        # and is not compatible with pre-existing resources. We first remove them.
        [
          helm_command_module::DeleteCommand.new(
            name: 'elastic-stack',
            rbac: cluster.platform_kubernetes_rbac?,
            files: files
          ).delete_command,
          Gitlab::Kubernetes::KubectlCmd.delete("pvc", "--selector", "release=elastic-stack", "--namespace", Gitlab::Kubernetes::Helm::NAMESPACE)
        ]
      end
    end
  end
end

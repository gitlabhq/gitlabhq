module Clusters
  module Applications
    class Helm < ActiveRecord::Base
      self.table_name = 'clusters_applications_helm'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus

      default_value_for :version, Gitlab::Kubernetes::Helm::HELM_VERSION

      def set_initial_status
        return unless not_installable?

        self.status = 'installable' if cluster&.platform_kubernetes_active?
      end

      def install_command
        Gitlab::Kubernetes::Helm::InitCommand.new(name)
      end
    end
  end
end

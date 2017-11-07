module Clusters
  module Applications
    class Helm < ActiveRecord::Base
      self.table_name = 'clusters_applications_helm'

      include ::Clusters::Concerns::ApplicationStatus

      belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

      default_value_for :version, Gitlab::Kubernetes::Helm::HELM_VERSION

      validates :cluster, presence: true

      after_initialize :set_initial_status

      def self.application_name
        self.to_s.demodulize.underscore
      end

      def set_initial_status
        return unless not_installable?

        self.status = 'installable' if cluster&.platform_kubernetes_active?
      end

      def name
        self.class.application_name
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(name, true)
      end
    end
  end
end

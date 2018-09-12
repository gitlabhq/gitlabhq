# frozen_string_literal: true

module Clusters
  module Applications
    class Knative < ActiveRecord::Base
      VERSION = '0.1.0'.freeze

      self.table_name = 'clusters_applications_knative'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData
      include AfterCommitQueue

      default_value_for :version, VERSION

      def set_initial_status
        return unless not_installable?

        self.status = 'installable' if cluster&.platform_kubernetes_active?
      end

      def install_command
        Gitlab::Kubernetes::Helm::KubectlCommand.new(
          name: name,
          scripts: scripts
        )
      end

      private

      def scripts
        [
          "kubectl apply -f https://raw.githubusercontent.com/knative/serving/v0.1.1/third_party/config/build/release.yaml",
          "kubectl apply -f https://github.com/knative/serving/releases/download/v0.1.1/release.yaml"
        ]
      end
    end
  end
end

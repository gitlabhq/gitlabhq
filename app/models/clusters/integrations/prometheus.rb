# frozen_string_literal: true

module Clusters
  module Integrations
    class Prometheus < ApplicationRecord
      include ::Clusters::Concerns::PrometheusClient
      include AfterCommitQueue

      self.table_name = 'clusters_integration_prometheus'
      self.primary_key = :cluster_id

      belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

      validates :cluster, presence: true
      validates :enabled, inclusion: { in: [true, false] }

      attr_encrypted :alert_manager_token,
        mode: :per_attribute_iv,
        key: Settings.attr_encrypted_db_key_base_32,
        algorithm: 'aes-256-gcm'

      default_value_for(:alert_manager_token) { SecureRandom.hex }

      after_destroy do
        run_after_commit do
          deactivate_project_services
        end
      end

      after_save do
        next unless enabled_before_last_save != enabled

        run_after_commit do
          if enabled
            activate_project_services
          else
            deactivate_project_services
          end
        end
      end

      def available?
        enabled?
      end

      private

      def activate_project_services
        ::Clusters::Applications::ActivateServiceWorker
          .perform_async(cluster_id, ::PrometheusService.to_param) # rubocop:disable CodeReuse/ServiceClass
      end

      def deactivate_project_services
        ::Clusters::Applications::DeactivateServiceWorker
          .perform_async(cluster_id, ::PrometheusService.to_param) # rubocop:disable CodeReuse/ServiceClass
      end
    end
  end
end

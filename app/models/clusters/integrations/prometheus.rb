# frozen_string_literal: true

module Clusters
  module Integrations
    class Prometheus < ApplicationRecord
      include ::Clusters::Concerns::PrometheusClient

      self.table_name = 'clusters_integration_prometheus'
      self.primary_key = :cluster_id

      belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

      validates :cluster, presence: true
      validates :enabled, inclusion: { in: [true, false] }

      def available?
        enabled?
      end
    end
  end
end

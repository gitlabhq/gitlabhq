# frozen_string_literal: true

module Clusters
  module Integrations
    class ElasticStack < ApplicationRecord
      include ::Clusters::Concerns::ElasticsearchClient
      include ::Clusters::Concerns::KubernetesLogger

      self.table_name = 'clusters_integration_elasticstack'
      self.primary_key = :cluster_id

      belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

      validates :cluster, presence: true
      validates :enabled, inclusion: { in: [true, false] }

      def available?
        enabled
      end

      def service_name
        chart_above_v3? ? 'elastic-stack-elasticsearch-master' : 'elastic-stack-elasticsearch-client'
      end

      def chart_above_v2?
        return true if chart_version.nil?

        Gem::Version.new(chart_version) >= Gem::Version.new('2.0.0')
      end

      def chart_above_v3?
        return true if chart_version.nil?

        Gem::Version.new(chart_version) >= Gem::Version.new('3.0.0')
      end
    end
  end
end

module Clusters
  module Applications
    class Helm < ActiveRecord::Base
      self.table_name = 'clusters_applications_helm'

      NAME = 'helm'.freeze

      include ::Clusters::Concerns::AppStatus

      belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

      default_value_for :version, Gitlab::Clusters::Helm::HELM_VERSION

      def name
        NAME
      end
    end
  end
end

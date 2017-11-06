module Clusters
  module Applications
    class Ingress < ActiveRecord::Base
      self.table_name = 'clusters_applications_ingress'

      include ::Clusters::Concerns::ApplicationStatus

      belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

      validates :cluster, presence: true

      default_value_for :ingress_type, :nginx
      default_value_for :version, :nginx

      enum ingress_type: {
        nginx: 1
      }

      def self.application_name
        self.to_s.demodulize.underscore
      end

      def name
        self.class.application_name
      end

      def chart
        'stable/nginx-ingress'
      end
    end
  end
end

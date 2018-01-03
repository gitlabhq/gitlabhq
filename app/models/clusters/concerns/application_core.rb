module Clusters
  module Concerns
    module ApplicationCore
      extend ActiveSupport::Concern

      included do
        belongs_to :cluster, class_name: 'Clusters::Cluster', foreign_key: :cluster_id

        validates :cluster, presence: true

        after_initialize :set_initial_status

        def set_initial_status
          return unless not_installable?

          self.status = 'installable' if cluster&.application_helm_installed?
        end

        def self.application_name
          self.to_s.demodulize.underscore
        end

        def name
          self.class.application_name
        end
      end
    end
  end
end

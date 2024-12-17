# frozen_string_literal: true

# Base module for monitoring services
#
# These services integrate with a deployment solution like Prometheus
# to provide additional features for environments.
module Integrations
  module Base
    module Monitoring
      extend ActiveSupport::Concern

      class_methods do
        def supported_events
          %w[]
        end
      end

      included do
        attribute :category, default: 'monitoring'
      end

      def can_query?
        raise NotImplementedError
      end

      def query(_, *_)
        raise NotImplementedError
      end
    end
  end
end

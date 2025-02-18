# frozen_string_literal: true

module Integrations
  module Base
    module MockMonitoring
      extend ActiveSupport::Concern

      include Base::Monitoring

      class_methods do
        def title
          'Mock monitoring'
        end

        def description
          'Mock monitoring service'
        end

        def to_param
          'mock_monitoring'
        end
      end

      included do
        def metrics(_environment)
          Gitlab::Json.parse(File.read(Rails.root.join('spec/fixtures/metrics.json')))
        end

        def testable?
          false
        end
      end
    end
  end
end

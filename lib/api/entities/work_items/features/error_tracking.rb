# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class ErrorTracking < Grape::Entity
          expose :sentry_issue_identifier, as: :identifier,
            documentation: { type: 'Integer', example: 12345 },
            expose_nil: true
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Concerns
    module AiWorkflowsAccess
      extend ActiveSupport::Concern

      class_methods do
        def allow_ai_workflows_access
          allow_access_with_scope :ai_workflows, if: ->(request) do
            request.get? || request.head? || request.post? || request.put?
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

class AccessibilityReportsComparerEntity < Grape::Entity
  expose :status

  expose :new_errors, using: AccessibilityErrorEntity
  expose :resolved_errors, using: AccessibilityErrorEntity
  expose :existing_errors, using: AccessibilityErrorEntity

  expose :summary do
    expose :total_count, as: :total
    expose :resolved_count, as: :resolved
    expose :errors_count, as: :errored
  end
end

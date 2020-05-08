# frozen_string_literal: true

class AccessibilityErrorEntity < Grape::Entity
  expose :code
  expose :type
  expose :typeCode, as: :type_code
  expose :message
  expose :context
  expose :selector
  expose :runner
  expose :runnerExtras, as: :runner_extras
end

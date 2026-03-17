# frozen_string_literal: true

module API
  module Entities
    class TaskCompletionStatus < Grape::Entity
      expose :count,
        documentation: { type: 'Integer', example: 5 }
      expose :completed_count,
        documentation: { type: 'Integer', example: 3 }
    end
  end
end

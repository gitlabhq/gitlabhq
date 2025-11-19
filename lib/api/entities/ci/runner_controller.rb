# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerController < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :description, documentation: { type: 'string', example: 'Controller for managing runner' }
        expose :created_at, documentation: { type: 'dateTime' }
        expose :updated_at, documentation: { type: 'dateTime' }
      end
    end
  end
end

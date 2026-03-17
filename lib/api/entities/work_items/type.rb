# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      class Type < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :name, documentation: { type: 'String', example: 'Issue' }
        expose :icon_name, documentation: { type: 'String', example: 'issue-type-issue' }
      end
    end
  end
end

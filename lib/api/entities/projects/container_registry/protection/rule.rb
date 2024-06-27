# frozen_string_literal: true

module API
  module Entities
    module Projects
      module ContainerRegistry
        module Protection
          class Rule < Grape::Entity
            expose :id, documentation: { type: 'integer', example: 1 }
            expose :project_id, documentation: { type: 'integer', example: 1 }
            expose :repository_path_pattern, documentation: { type: 'string', example: 'flightjs/flight0' }
            expose :minimum_access_level_for_push, documentation: { type: 'string', example: 'maintainer' }
            expose :minimum_access_level_for_delete, documentation: { type: 'string', example: 'maintainer' }
          end
        end
      end
    end
  end
end

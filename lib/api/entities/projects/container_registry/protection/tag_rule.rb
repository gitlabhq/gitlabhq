# frozen_string_literal: true

module API
  module Entities
    module Projects
      module ContainerRegistry
        module Protection
          class TagRule < Grape::Entity
            expose :id, documentation: { type: 'Integer', example: 1 }
            expose :project_id, documentation: { type: 'Integer', example: 123 }
            expose :tag_name_pattern, documentation: { type: 'String', example: 'v*-release' }
            expose :minimum_access_level_for_push, documentation: { type: 'String', example: 'maintainer' }
            expose :minimum_access_level_for_delete, documentation: { type: 'String', example: 'maintainer' }
          end
        end
      end
    end
  end
end

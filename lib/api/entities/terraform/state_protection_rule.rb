# frozen_string_literal: true

module API
  module Entities
    module Terraform
      class StateProtectionRule < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :project_id, documentation: { type: 'Integer', example: 1 }
        expose :state_name, documentation: { type: 'String', example: 'production' }
        expose :minimum_access_level_for_write, documentation: { type: 'String', example: 'maintainer' }
        expose :allowed_from, documentation: { type: 'String', example: 'ci_only' }
      end
    end
  end
end

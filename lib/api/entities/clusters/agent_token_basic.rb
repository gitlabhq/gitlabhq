# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class AgentTokenBasic < Grape::Entity
        expose :id, documentation: { type: 'Integer', format: 'int64', example: 1 }
        expose :name, documentation: { type: 'String' }
        expose :description, documentation: { type: 'String' }
        expose :agent_id, documentation: { type: 'Integer', format: 'int64', example: 1 }
        expose :status, documentation: { type: 'String' }
        expose :created_at, documentation: { type: 'DateTime' }
        expose :created_by_user_id, documentation: { type: 'Integer', format: 'int64', example: 1 }
      end
    end
  end
end

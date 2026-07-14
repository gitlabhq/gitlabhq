# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class Agent < Grape::Entity
        expose :id, documentation: { type: 'Integer', format: 'int64', example: 1 }
        expose :name, documentation: { type: 'String' }
        expose :project, using: ::API::Entities::ProjectIdentity, as: :config_project
        expose :created_at, documentation: { type: 'DateTime' }
        expose :created_by_user_id, documentation: { type: 'Integer', format: 'int64', example: 1 }
      end
    end
  end
end

API::Entities::Clusters::Agent.prepend_mod

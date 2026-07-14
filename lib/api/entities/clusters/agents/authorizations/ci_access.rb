# frozen_string_literal: true

module API
  module Entities
    module Clusters
      module Agents
        module Authorizations
          class CiAccess < Grape::Entity
            expose :agent_id, as: :id, documentation: { type: 'Integer', format: 'int64', example: 1 }
            expose :config_project, using: ::API::Entities::ProjectIdentity
            expose :config, as: :configuration, documentation: { type: 'Hash' }
          end
        end
      end
    end
  end
end

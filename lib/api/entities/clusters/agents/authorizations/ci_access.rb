# frozen_string_literal: true

module API
  module Entities
    module Clusters
      module Agents
        module Authorizations
          class CiAccess < Grape::Entity
            expose :agent_id, as: :id
            expose :config_project, with: Entities::ProjectIdentity
            expose :config, as: :configuration
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class AgentAuthorization < Grape::Entity
        expose :agent_id, as: :id
        expose :project, with: Entities::ProjectIdentity, as: :config_project
        expose :config, as: :configuration
      end
    end
  end
end

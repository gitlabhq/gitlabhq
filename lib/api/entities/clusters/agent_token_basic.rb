# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class AgentTokenBasic < Grape::Entity
        expose :id
        expose :name
        expose :description
        expose :agent_id
        expose :status
        expose :created_at
        expose :created_by_user_id
      end
    end
  end
end

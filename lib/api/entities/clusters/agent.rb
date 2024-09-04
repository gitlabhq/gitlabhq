# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class Agent < Grape::Entity
        expose :id
        expose :name
        expose :project, with: Entities::ProjectIdentity, as: :config_project
        expose :created_at
        expose :created_by_user_id
      end
    end
  end
end

API::Entities::Clusters::Agent.prepend_mod

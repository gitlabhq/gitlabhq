# frozen_string_literal: true

module API
  module Entities
    module Clusters
      class Agent < Grape::Entity
        expose :id
        expose :project, with: Entities::ProjectIdentity, as: :config_project
      end
    end
  end
end

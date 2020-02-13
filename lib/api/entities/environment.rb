# frozen_string_literal: true

module API
  module Entities
    class Environment < Entities::EnvironmentBasic
      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state
    end
  end
end

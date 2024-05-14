# frozen_string_literal: true

module API
  module Entities
    class Environment < Entities::EnvironmentBasic
      include RequestAwareEntity

      expose :tier, documentation: { type: 'string', example: 'development' }
      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state, documentation: { type: 'string', example: 'available' }
      expose :auto_stop_at, documentation: { type: 'dateTime', example: '2019-05-25T18:55:13.252Z' }
    end
  end
end

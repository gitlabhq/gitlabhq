# frozen_string_literal: true

module API
  module Entities
    class Deployment < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 41 }
      expose :iid, documentation: { type: 'Integer', example: 1 }
      expose :ref, documentation: { type: 'String', example: 'main' }
      expose :sha, documentation: { type: 'String', example: '99d03678b90d914dbb1b109132516d71a4a03ea8' }
      expose :created_at, documentation: { type: 'DateTime', example: '2016-08-11T11:32:35.444Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2016-08-11T11:32:35.444Z' }
      expose :user,        using: Entities::UserBasic
      expose :environment, using: Entities::EnvironmentBasic
      expose :deployable,  using: Entities::Ci::Job
      expose :status, documentation: { type: 'String', example: 'created' }
    end
  end
end

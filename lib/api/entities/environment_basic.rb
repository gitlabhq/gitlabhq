# frozen_string_literal: true

module API
  module Entities
    class EnvironmentBasic < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :name, documentation: { type: 'String', example: 'deploy' }
      expose :slug, documentation: { type: 'String', example: 'deploy' }
      expose :external_url, documentation: { type: 'String', example: 'https://deploy.gitlab.example.com' }
      expose :created_at, documentation: { type: 'DateTime', example: '2019-05-25T18:55:13.252Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2019-05-25T18:55:13.252Z' }
    end
  end
end

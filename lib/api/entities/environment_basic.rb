# frozen_string_literal: true

module API
  module Entities
    class EnvironmentBasic < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :name, documentation: { type: 'string', example: 'deploy' }
      expose :slug, documentation: { type: 'string', example: 'deploy' }
      expose :external_url, documentation: { type: 'string', example: 'https://deploy.gitlab.example.com' }
      expose :created_at, documentation: { type: 'dateTime', example: '2019-05-25T18:55:13.252Z' }
      expose :updated_at, documentation: { type: 'dateTime', example: '2019-05-25T18:55:13.252Z' }
    end
  end
end

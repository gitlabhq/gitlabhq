# frozen_string_literal: true

module API
  module Entities
    class CommitStatus < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 93 }
      expose :sha, documentation: { type: 'string', example: '18f3e63d05582537db6d183d9d557be09e1f90c8' }
      expose :ref, documentation: { type: 'string', example: 'develop' }
      expose :status, documentation: { type: 'string', example: 'success' }
      expose :name, documentation: { type: 'string', example: 'default' }
      expose :target_url, documentation: {
        type: 'string',
        example: 'https://gitlab.example.com/janedoe/gitlab-foss/builds/91'
      }
      expose :description, documentation: { type: 'string' }
      expose :created_at, documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
      expose :started_at, documentation: { type: 'dateTime', example: '2016-01-20T08:40:25.832Z' }
      expose :finished_at, documentation: { type: 'dateTime', example: '2016-01-21T08:40:25.832Z' }
      expose :allow_failure, documentation: { type: 'boolean', example: false }
      expose :coverage, documentation: { type: 'number', format: 'float', example: 98.29 }
      expose :pipeline_id, documentation: { type: 'integer', example: 101 }

      expose :author, using: Entities::UserBasic
    end
  end
end

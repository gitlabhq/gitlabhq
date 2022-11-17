# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Pipeline < PipelineBasic
        expose :before_sha, documentation: { type: 'string', example: 'a91957a858320c0e17f3a0eca7cfacbff50ea29a' }
        expose :tag, documentation: { type: 'boolean', example: false }
        expose :yaml_errors, documentation: { type: 'string', example: "widgets:build: needs 'widgets:test'" }

        expose :user, with: Entities::UserBasic
        expose :created_at, documentation: { type: 'dateTime', example: '2015-12-24T15:51:21.880Z' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:31.198Z' }
        expose :started_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:30.733Z' }
        expose :finished_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:31.198Z' }
        expose :committed_at, documentation: { type: 'dateTime', example: '2015-12-24T15:51:21.880Z' }
        expose :duration,
          documentation: { type: 'integer', desc: 'Time spent running in seconds', example: 127 }
        expose :queued_duration,
          documentation: { type: 'integer', desc: 'Time spent enqueued in seconds', example: 63 }
        expose :coverage, documentation: { type: 'number', format: 'float', example: 98.29 } do |pipeline|
          pipeline.present.coverage
        end
        expose :detailed_status, using: DetailedStatusEntity do |pipeline, options|
          pipeline.detailed_status(options[:current_user])
        end
      end
    end
  end
end

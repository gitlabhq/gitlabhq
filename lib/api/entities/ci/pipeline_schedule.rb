# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineSchedule < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 13 }
        expose :description, documentation: { type: 'string', example: 'Test schedule pipeline' }
        expose :ref, documentation: { type: 'string', example: 'develop' }
        expose :cron, documentation: { type: 'string', example: '* * * * *' }
        expose :cron_timezone, documentation: { type: 'string', example: 'Asia/Tokyo' }
        expose :next_run_at, documentation: { type: 'dateTime', example: '2017-05-19T13:41:00.000Z' }
        expose :active, documentation: { type: 'boolean', example: true }
        expose :created_at, documentation: { type: 'dateTime', example: '2017-05-19T13:31:08.849Z' }
        expose :updated_at, documentation: { type: 'dateTime', example: '2017-05-19T13:40:17.727Z' }
        expose :owner, using: ::API::Entities::UserBasic
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    module Ci
      class PipelineSchedule < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 13 }
        expose :description, documentation: { type: 'String', example: 'Test schedule pipeline' }
        expose :ref, documentation: { type: 'String', example: 'develop' }
        expose :cron, documentation: { type: 'String', example: '* * * * *' }
        expose :cron_timezone, documentation: { type: 'String', example: 'Asia/Tokyo' }
        expose :next_run_at, documentation: { type: 'DateTime', example: '2017-05-19T13:41:00.000Z' }
        expose :active, documentation: { type: 'Boolean', example: true }
        expose :created_at, documentation: { type: 'DateTime', example: '2017-05-19T13:31:08.849Z' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2017-05-19T13:40:17.727Z' }
        expose :owner, using: ::API::Entities::UserBasic
        expose :inputs, using: Entities::Ci::Input
      end
    end
  end
end

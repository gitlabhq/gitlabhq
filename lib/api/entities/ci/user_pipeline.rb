# frozen_string_literal: true

module API
  module Entities
    module Ci
      class UserPipeline < PipelineBasicWithMetadata
        expose :project, using: ::API::Entities::ProjectIdentity
        expose :started_at, documentation: { type: 'DateTime', example: '2022-10-21T16:49:50.000+02:00' }
        expose :finished_at, documentation: { type: 'DateTime', example: '2022-10-21T16:52:12.000+02:00' }
        expose :duration,
          documentation: { type: 'Integer', desc: 'Time spent running in seconds', example: 127 }
        expose :queued_duration,
          documentation: { type: 'Integer', desc: 'Time spent queued in seconds', example: 63 }

        # rubocop:disable API/EntityFieldType -- DetailedStatusEntity is a serializer reused across the API (see Entities::Ci::Pipeline)
        expose :detailed_status, using: ::DetailedStatusEntity do |pipeline, options|
          pipeline.detailed_status(options[:current_user])
        end
        # rubocop:enable API/EntityFieldType

        expose :merge_request, using: ::API::Entities::Ci::PipelineMergeRequest,
          if: ->(pipeline, options) {
            pipeline.merge_request_id &&
              Ability.allowed?(options[:current_user], :read_merge_request, pipeline.merge_request)
          }
      end
    end
  end
end

# frozen_string_literal: true

# This class represents the metadata for the pipeline creation process up until it succeeds and is persisted or fails
# It has the "in progress" status until it succeeds or fails.
# It stores the data in Redis and it is retained for 5 minutes.
# The structure of the data is:
# {
#   "REDIS_KEY": {
#     "CREATION_ID": {
#       "error" => "ERROR MESSAGE" <- this field is only present for failed creations
#       "pipeline_id": "PIPELINE_ID" <- this field is only present for successful creations
#       "status": "STATUS"
#     }
#   }
# }
#
# NOTE: All hash keys should be strings because this data is JSONified for Redis and when passing the creation key and
# ID into pipeline creation workers
#
module Ci
  module PipelineCreation
    class Requests
      FAILED = 'failed'
      # GraphQL does not seem to accept spaces so we need to update the regex
      IN_PROGRESS = 'in_progress'
      SUCCEEDED = 'succeeded'
      STATUSES = [FAILED, IN_PROGRESS, SUCCEEDED].freeze

      REDIS_EXPIRATION_TIME = 300
      MERGE_REQUEST_REDIS_KEY = "pipeline_creation:projects:{%{project_id}}:mrs:{%{mr_id}}"

      class << self
        def failed(request, error)
          return unless request.present?

          hset(request, FAILED, error: error)
        end

        def succeeded(request, pipeline_id)
          return unless request.present?

          hset(request, SUCCEEDED, pipeline_id: pipeline_id)
        end

        def start_for_merge_request(merge_request)
          request = { 'key' => merge_request_key(merge_request), 'id' => generate_id }

          hset(request, IN_PROGRESS)

          request
        end

        def pipeline_creating_for_merge_request?(merge_request)
          key = merge_request_key(merge_request)

          requests = Gitlab::Redis::SharedState.with { |redis| redis.hvals(key) }

          return false unless requests.present?

          requests
            .map { |request| Gitlab::Json.parse(request) }
            .any? { |request| request['status'] == IN_PROGRESS }
        end

        def merge_request_key(merge_request)
          format(MERGE_REQUEST_REDIS_KEY, project_id: merge_request.project_id, mr_id: merge_request.id)
        end

        def hset(request, status, pipeline_id: nil, error: nil)
          Gitlab::Redis::SharedState.with do |redis|
            redis.multi do |transaction|
              transaction.hset(
                request['key'], request['id'],
                { 'status' => status, 'pipeline_id' => pipeline_id, 'error' => error }.compact.to_json
              )

              transaction.expire(request['key'], REDIS_EXPIRATION_TIME)
            end
          end
        end

        def hget(request)
          Gitlab::Redis::SharedState.with { |redis| Gitlab::Json.parse(redis.hget(request['key'], request['id'])) }
        end

        def generate_id
          SecureRandom.uuid
        end
      end
    end
  end
end

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
# NOTE: For general project pipelines, `REDIS_KEY` includes the project ID and the request ID for the pipeline creation.
# This means that the request ID is referenced twice when fetching the request data - in `REDIS_KEY` and in
# `CREATION_ID`. It also means that the value for `REDIS_KEY` will only ever contain one pipeline creation request.
# This is somewhat unexpected, but it is necessary in order to match the data structure for merge request pipelines
# (which can have several pipelines creation requests stored under their `REDIS_KEY`). We've decided that maintaining
# two separate data structures is more confusing and results in more code, so it's better to match the data structures
# even if it means that we have a redundant use of the request ID when storing general project pipeline creation
# requests.
#
# NOTE: The `REDIS_KEY` for general project pipelines MUST contain the request ID (not only the project ID) in order to
# ensure that the keys expire. Some projects are so active that their creation request data will never expire from
# Redis if we store all the pipeline creations for a project under one key.
#
# NOTE: All hash keys should be strings because this data is JSONified for Redis and the pipeline creation workers.
#
# TODO: In an attempt to make the Redis data easier to understand, we plan to simplify the way we store MR pipeline
# creation data in https://gitlab.com/gitlab-org/gitlab/-/issues/509925
module Ci
  module PipelineCreation
    class Requests
      FAILED = 'failed'
      IN_PROGRESS = 'in_progress'
      SUCCEEDED = 'succeeded'
      STATUSES = [FAILED, IN_PROGRESS, SUCCEEDED].freeze

      REDIS_EXPIRATION_TIME = 300
      PROJECT_REDIS_KEY = "pipeline_creation:projects:{%{project_id}}"
      MERGE_REQUEST_REDIS_KEY = "#{PROJECT_REDIS_KEY}:mrs:{%{mr_id}}".freeze
      REQUEST_REDIS_KEY = "#{PROJECT_REDIS_KEY}:request:{%{request_id}}".freeze

      class << self
        def failed(request, error)
          return unless request.present?

          hset(request, FAILED, error: error)
        end

        def succeeded(request, pipeline_id)
          return unless request.present?

          hset(request, SUCCEEDED, pipeline_id: pipeline_id)
        end

        def start_for_project(project)
          request_id = generate_id
          request = { 'key' => request_key(project, request_id), 'id' => request_id }

          hset(request, IN_PROGRESS)

          request
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

        def get_request(project, request_id)
          hget({ 'key' => request_key(project, request_id), 'id' => request_id })
        end

        def request_key(project, request_id)
          format(REQUEST_REDIS_KEY, project_id: project.id, request_id: request_id)
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

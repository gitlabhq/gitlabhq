# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobBasic < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :status, documentation: { type: 'string', example: 'waiting_for_resource' }
        expose :stage, documentation: { type: 'string', example: 'deploy' }
        expose :name, documentation: { type: 'string', example: 'deploy_to_production' }
        expose :ref, documentation: { type: 'string', example: 'main' }
        expose :tag, documentation: { type: 'boolean' }
        expose :coverage, documentation: { type: 'number', format: 'float', example: 98.29 }
        expose :allow_failure, documentation: { type: 'boolean' }
        expose :created_at, documentation: { type: 'dateTime', example: '2015-12-24T15:51:21.880Z' }
        expose :started_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:30.733Z' }
        expose :finished_at, documentation: { type: 'dateTime', example: '2015-12-24T17:54:31.198Z' }
        expose :erased_at, documentation: { type: 'dateTime', example: '2015-12-24T18:00:29.728Z' }
        expose :duration,
          documentation: { type: 'number', format: 'float', desc: 'Time spent running', example: 0.465 }
        expose :queued_duration,
          documentation: { type: 'number', format: 'float', desc: 'Time spent enqueued', example: 0.123 }
        expose :user, with: ::API::Entities::User
        expose :commit, with: ::API::Entities::Commit
        expose :pipeline, with: ::API::Entities::Ci::PipelineBasic
        expose :failure_reason,
          documentation: { type: 'string', example: 'script_failure' }, if: ->(job) { job.failed? }

        expose(
          :web_url,
          documentation: { type: 'string', example: 'https://example.com/foo/bar/-/jobs/1' }
        ) do |job, _options|
          Gitlab::Routing.url_helpers.project_job_url(job.project, job)
        end

        expose :project do
          expose :ci_job_token_scope_enabled, documentation: { type: 'string', example: false } do |job|
            job.project.ci_outbound_job_token_scope_enabled?
          end
        end
      end
    end
  end
end

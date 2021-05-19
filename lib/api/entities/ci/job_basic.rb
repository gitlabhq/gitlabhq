# frozen_string_literal: true

module API
  module Entities
    module Ci
      class JobBasic < Grape::Entity
        expose :id, :status, :stage, :name, :ref, :tag, :coverage, :allow_failure
        expose :created_at, :started_at, :finished_at
        expose :duration,
               documentation: { type: 'Floating', desc: 'Time spent running' }
        expose :queued_duration,
               documentation: { type: 'Floating', desc: 'Time spent enqueued' }
        expose :user, with: ::API::Entities::User
        expose :commit, with: ::API::Entities::Commit
        expose :pipeline, with: ::API::Entities::Ci::PipelineBasic

        expose :web_url do |job, _options|
          Gitlab::Routing.url_helpers.project_job_url(job.project, job)
        end
      end
    end
  end
end

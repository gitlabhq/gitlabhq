# frozen_string_literal: true

module Ml
  class CandidateDetailsPresenter
    include Rails.application.routes.url_helpers

    def initialize(candidate)
      @candidate = candidate
    end

    def present
      data = {
        candidate: {
          info: {
            iid: candidate.iid,
            eid: candidate.eid,
            path_to_artifact: link_to_artifact,
            experiment_name: candidate.experiment.name,
            path_to_experiment: link_to_experiment,
            path: link_to_details,
            status: candidate.status,
            ci_job: job_info
          },
          params: candidate.params,
          metrics: candidate.latest_metrics,
          metadata: candidate.metadata
        }
      }

      Gitlab::Json.generate(data)
    end

    private

    attr_reader :candidate

    def job_info
      return unless candidate.from_ci?

      build = candidate.ci_build

      {
        path: project_job_path(build.project, build),
        name: build.name,
        **user_info(build.user) || {},
        **mr_info(build.pipeline.merge_request) || {}
      }
    end

    def user_info(user)
      return unless user

      {
        user: {
          path: user_path(user),
          username: user.username
        }
      }
    end

    def mr_info(mr)
      return unless mr

      {
        merge_request: {
          path: project_merge_request_path(mr.project, mr),
          title: mr.title
        }
      }
    end

    def link_to_artifact
      artifact = candidate.artifact

      return unless artifact.present?

      project_package_path(candidate.project, artifact)
    end

    def link_to_details
      project_ml_candidate_path(candidate.project, candidate.iid)
    end

    def link_to_experiment
      project_ml_experiment_path(candidate.project, candidate.experiment.iid)
    end
  end
end

# frozen_string_literal: true

module Ml
  class CandidateDetailsPresenter
    include Rails.application.routes.url_helpers

    def initialize(candidate, current_user)
      @candidate = candidate
      @current_user = current_user
    end

    def present
      {
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
          metrics: candidate.metrics,
          metadata: candidate.metadata
        }
      }
    end

    def present_as_json
      Gitlab::Json.generate(present.deep_transform_keys { |k| k.to_s.camelize(:lower) })
    end

    private

    attr_reader :candidate, :current_user

    def job_info
      return unless candidate.from_ci? && current_user.can?(:read_build, candidate.ci_build)

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
          username: user.username,
          name: user.name,
          avatar: user.avatar_url
        }
      }
    end

    def mr_info(mr)
      return unless mr

      {
        merge_request: {
          path: project_merge_request_path(mr.project, mr),
          iid: mr.iid,
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

# frozen_string_literal: true

module Ml
  class CandidateDetailsPresenter
    def initialize(candidate, current_user)
      @candidate = candidate
      @current_user = current_user
    end

    # rubocop:disable Metrics/AbcSize -- Monoton complexity
    def present
      {
        candidate: {
          info: {
            iid: candidate.iid,
            eid: candidate.eid,
            gid: candidate.to_global_id.to_s,
            path_to_artifact: link_to_artifact,
            experiment_name: candidate.experiment.name,
            path_to_experiment: link_to_experiment,
            path: link_to_details,
            status: candidate.status,
            ci_job: job_info,
            created_at: candidate.created_at,
            author_web_url: candidate.user&.namespace&.web_url,
            author_name: candidate.user&.name,
            promote_path: url_helpers.promote_project_ml_candidate_path(candidate.project, candidate.iid),
            can_promote: can_promote
          },
          params: candidate.params,
          metrics: candidate.metrics,
          metadata: candidate.metadata,
          projectPath: candidate.project.full_path,
          can_write_model_experiments: current_user&.can?(:write_model_experiments, candidate.project),
          markdown_preview_path: url_helpers.project_preview_markdown_path(candidate.project),
          model_gid: candidate.experiment.model&.to_global_id.to_s,
          latest_version: candidate.experiment.model&.latest_version&.version
        }
      }
    end
    # rubocop:enable Metrics/AbcSize

    def present_as_json
      Gitlab::Json.generate(present.deep_transform_keys { |k| k.to_s.camelize(:lower) })
    end

    private

    attr_reader :candidate, :current_user

    def job_info
      return unless candidate.from_ci? && current_user&.can?(:read_build, candidate.ci_build)

      build = candidate.ci_build

      {
        path: url_helpers.project_job_path(build.project, build),
        name: build.name,
        **user_info(build.user) || {},
        **mr_info(build.pipeline.merge_request) || {}
      }
    end

    def user_info(user)
      return unless user

      {
        user: {
          path: url_helpers.user_path(user),
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
          path: url_helpers.project_merge_request_path(mr.project, mr),
          iid: mr.iid,
          title: mr.title
        }
      }
    end

    def link_to_artifact
      artifact = candidate.artifact

      return unless artifact.present?

      url_helpers.project_package_path(candidate.project, artifact)
    end

    def link_to_details
      url_helpers.project_ml_candidate_path(candidate.project, candidate.iid)
    end

    def link_to_experiment
      url_helpers.project_ml_experiment_path(candidate.project, candidate.experiment.iid)
    end

    def url_helpers
      Gitlab::Routing.url_helpers
    end

    def can_promote
      candidate.model_version_id.nil? &&
        candidate.experiment.model_id.present? &&
        current_user&.can?(:write_model_registry, candidate.project)
    end
  end
end

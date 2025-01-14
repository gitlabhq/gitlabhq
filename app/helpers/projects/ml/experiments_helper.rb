# frozen_string_literal: true
module Projects
  module Ml
    module ExperimentsHelper
      require 'json'
      include ActionView::Helpers::NumberHelper

      def experiment_as_data(project, experiment)
        data = {
          id: experiment.id,
          name: experiment.name,
          metadata: experiment.metadata,
          path: link_to_experiment(project, experiment),
          model_id: experiment.model&.id,
          created_at: experiment.created_at,
          user: {
            id: experiment.user&.id,
            name: experiment.user&.name,
            path: experiment&.user ? user_path(experiment&.user) : nil
          }
        }

        Gitlab::Json.generate(data)
      end

      def candidates_table_items(candidates, current_user)
        items = candidates.map do |candidate|
          {
            **candidate.params.to_h { |p| [p.name, p.value] },
            **candidate.latest_metrics.to_h { |m| [m.name, number_with_precision(m.value, precision: 4)] },
            ci_job: job_info(candidate, current_user),
            artifact: link_to_artifact(candidate),
            details: link_to_details(candidate),
            name: candidate.name,
            created_at: candidate.created_at,
            user: user_info(candidate, current_user)
          }
        end

        Gitlab::Json.generate(items)
      end

      def unique_logged_names(candidates, &selector)
        Gitlab::Json.generate(candidates.flat_map(&selector).map(&:name).uniq)
      end

      def experiments_as_data(project, experiments)
        data = experiments.map do |experiment|
          {
            name: experiment.name,
            path: link_to_experiment(project, experiment),
            candidate_count: experiment.candidate_count,
            updated_at: experiment.updated_at,
            user: {
              id: experiment.user&.id,
              name: experiment.user&.name,
              path: experiment&.user ? user_path(experiment&.user) : nil,
              avatar_url: experiment.user&.avatar_url
            }
          }
        end

        Gitlab::Json.generate(data)
      end

      def page_info(paginator)
        {
          has_next_page: paginator.has_next_page?,
          has_previous_page: paginator.has_previous_page?,
          start_cursor: paginator.cursor_for_previous_page,
          end_cursor: paginator.cursor_for_next_page
        }
      end

      def formatted_page_info(page_info)
        Gitlab::Json.generate(page_info)
      end

      def link_to_artifact(candidate)
        artifact = candidate.artifact

        return unless artifact.present?

        project_package_path(candidate.project, artifact)
      end

      def link_to_details(candidate)
        project_ml_candidate_path(candidate.project, candidate.iid)
      end

      def job_info(candidate, user)
        return unless candidate.from_ci? && can?(user, :read_build, candidate.ci_build)

        build = candidate.ci_build

        {
          path: project_job_path(build.project, build),
          name: build.name
        }
      end

      def link_to_experiment(project, experiment)
        project_ml_experiment_path(project, experiment.iid)
      end

      def user_info(candidate, current_user)
        user =
          if candidate.from_ci?
            candidate.ci_build.user if can?(current_user, :read_build, candidate.ci_build)
          else
            candidate.user
          end

        return unless user.present?

        {
          username: user.username,
          path: user_path(user)
        }
      end
    end
  end
end

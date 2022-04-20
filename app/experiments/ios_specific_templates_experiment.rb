# frozen_string_literal: true

class IosSpecificTemplatesExperiment < ApplicationExperiment
  before_run(if: :skip_experiment) { throw(:abort) } # rubocop:disable Cop/BanCatchThrow

  private

  def skip_experiment
    actor_not_able_to_create_pipelines? ||
      project_targets_non_ios_platforms? ||
      project_has_gitlab_ci? ||
      project_has_pipelines?
  end

  def actor_not_able_to_create_pipelines?
    !context.actor.is_a?(User) || !context.actor.can?(:create_pipeline, context.project)
  end

  def project_targets_non_ios_platforms?
    context.project.project_setting.target_platforms.exclude?('ios')
  end

  def project_has_gitlab_ci?
    context.project.has_ci? && context.project.builds_enabled?
  end

  def project_has_pipelines?
    context.project.all_pipelines.count > 0
  end
end

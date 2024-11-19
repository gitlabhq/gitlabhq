# frozen_string_literal: true

class StageEntity < Grape::Entity
  include RequestAwareEntity

  expose :name
  # This is temporary and will be removed with the migration of pipelines tables to GraphQL: https://gitlab.com/gitlab-org/gitlab/-/issues/461917
  expose :id

  expose :title do |stage|
    "#{stage.name}: #{detailed_status.label}"
  end

  expose :groups,
    if: ->(_, opts) { opts[:grouped] },
    with: JobGroupEntity

  expose :ordered_latest_statuses, as: :latest_statuses, if: ->(_, opts) { opts[:details] }, with: Ci::JobEntity

  expose :ordered_retried_statuses, as: :retried, if: ->(_, opts) { opts[:retried] }, with: Ci::JobEntity

  expose :detailed_status, as: :status, with: DetailedStatusEntity

  expose :path do |stage|
    project_pipeline_path(
      stage.pipeline.project,
      stage.pipeline,
      anchor: stage.name)
  end

  expose :dropdown_path do |stage|
    stage_project_pipeline_path(
      stage.pipeline.project,
      stage.pipeline,
      stage: stage.name,
      format: :json)
  end

  private

  alias_method :stage, :object

  def detailed_status
    stage.detailed_status(request.current_user)
  end
end

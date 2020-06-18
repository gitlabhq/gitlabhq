# frozen_string_literal: true

class PipelineSerializer < BaseSerializer
  include WithPagination
  entity PipelineDetailsEntity

  # rubocop: disable CodeReuse/ActiveRecord
  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.preload(preloaded_relations)
    end

    if paginated?
      resource = paginator.paginate(resource)
    end

    if opts.delete(:preload)
      resource = Gitlab::Ci::Pipeline::Preloader.preload!(resource)
    end

    super(resource, opts)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def represent_status(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:status] }] })
    data.dig(:details, :status) || {}
  end

  def represent_stages(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:stages] }], preload: true })
    data.dig(:details, :stages) || []
  end

  private

  def preloaded_relations
    [
      :cancelable_statuses,
      :latest_statuses_ordered_by_stage,
      :manual_actions,
      :retryable_builds,
      :scheduled_actions,
      :stages,
      :trigger_requests,
      :user,
      {
        downloadable_artifacts: {
          project: [:route, { namespace: :route }],
          job: []
        },
        failed_builds: %i(project metadata),
        merge_request: {
          source_project: [:route, { namespace: :route }],
          target_project: [:route, { namespace: :route }]
        },
        pending_builds: :project,
        project: [:route, { namespace: :route }],
        triggered_by_pipeline: [:project, :user],
        triggered_pipelines: [:project, :user]
      }
    ]
  end
end

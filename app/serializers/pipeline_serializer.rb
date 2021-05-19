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
      :retryable_builds,
      :stages,
      :latest_statuses,
      :trigger_requests,
      :user,
      {
        manual_actions: :metadata,
        scheduled_actions: :metadata,
        failed_builds: %i(project metadata),
        merge_request: {
          source_project: [:route, { namespace: :route }],
          target_project: [:route, { namespace: :route }]
        },
        pending_builds: :project,
        project: [:route, { namespace: :route }],
        triggered_by_pipeline: [{ project: [:route, { namespace: :route }] }, :user],
        triggered_pipelines: [
          {
            project: [:route, { namespace: :route }]
          },
          :source_job,
          :latest_statuses,
          :user
        ]
      }
    ]
  end
end

PipelineSerializer.prepend_mod_with('PipelineSerializer')

# frozen_string_literal: true

class PipelineSerializer < BaseSerializer
  include WithPagination
  entity PipelineDetailsEntity

  # rubocop: disable CodeReuse/ActiveRecord
  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.preload([
        :stages,
        :retryable_builds,
        :cancelable_statuses,
        :trigger_requests,
        { triggered_by_pipeline: [:project, :user] },
        { triggered_pipelines: [:project, :user] },
        :manual_actions,
        :artifacts,
        {
          pending_builds: :project,
          project: [:route, { namespace: :route }],
          artifacts: {
            project: [:route, { namespace: :route }]
          }
        }
      ])
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
end

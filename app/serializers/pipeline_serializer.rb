class PipelineSerializer < BaseSerializer
  include WithPagination

  InvalidResourceError = Class.new(StandardError)

  entity PipelineDetailsEntity

  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)

      resource = resource.preload([
        :retryable_builds,
        :cancelable_statuses,
        :trigger_requests,
        :project,
        :manual_actions,
        :artifacts,
        { pending_builds: :project }
      ])
    end

    if paginated?
      super(@paginator.paginate(resource), opts)
    else
      super(resource, opts)
    end
  end

  def represent_status(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:status] }] })
    data.dig(:details, :status) || {}
  end

  def represent_stages(resource)
    return {} unless resource.present?

    data = represent(resource, { only: [{ details: [:stages] }] })
    data.dig(:details, :stages) || []
  end
end

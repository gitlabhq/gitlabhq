class PipelineSerializer < BaseSerializer
  InvalidResourceError = Class.new(StandardError)

  entity PipelineEntity

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.preload([
        :retryable_builds,
        :cancelable_statuses,
        :trigger_requests,
        :project,
        { pending_builds: :project },
        { manual_actions: :project },
        { artifacts: :project }
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

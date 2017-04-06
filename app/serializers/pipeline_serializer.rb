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
      project_includes = [ { namespace: :route }, :route ]
      resource = resource.includes(
        :retryable_builds,
        :cancelable_statuses,
        :trigger_requests
      )
      resource = resource.includes(
        project: project_includes,
        pending_builds: [:project],
        manual_actions: { project: project_includes },
        artifacts: { project: project_includes }
      )
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
end

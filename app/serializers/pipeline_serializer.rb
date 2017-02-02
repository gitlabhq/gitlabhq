class PipelineSerializer < BaseSerializer
  class InvalidResourceError < StandardError; end

  entity PipelineEntity

  def with_pagination(request, response)
    tap { @paginator = Paginator.new(request, response) }
  end

  def paginated?
    defined?(@paginator)
  end

  def represent(resource, opts = {})
    if paginated?
      raise InvalidResourceError unless resource.respond_to?(:page)

      resource = resource.includes(project: :namespace)
      super(@paginator.paginate(resource), opts)
    else
      super(resource, opts)
    end
  end
end

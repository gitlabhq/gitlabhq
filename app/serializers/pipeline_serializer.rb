class PipelineSerializer < BaseSerializer
  class InvalidResourceError < StandardError; end

  entity PipelineEntity

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    if resource.is_a?(ActiveRecord::Relation)
      resource = resource.includes(project: :namespace)
    end

    if paginated?
      super(@paginator.paginate(resource), opts)
    else
      super(resource, opts)
    end
  end
end

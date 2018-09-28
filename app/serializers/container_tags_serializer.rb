# frozen_string_literal: true

class ContainerTagsSerializer < BaseSerializer
  entity ContainerTagEntity

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    resource = @paginator.paginate(resource) if paginated?

    super(resource, opts)
  end
end

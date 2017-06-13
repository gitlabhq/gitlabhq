class GroupSerializer < BaseSerializer
  entity GroupEntity

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    if paginated?
      super(@paginator.paginate(resource), opts)
    else
      super(resource, opts)
    end
  end
end

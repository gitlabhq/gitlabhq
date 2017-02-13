class EnvironmentSerializer < BaseSerializer
  Item = Struct.new(:name, :size, :latest)

  entity EnvironmentEntity

  def within_folders
    tap { @itemize = true }
  end

  def with_pagination(request, response)
    tap { @paginator = Gitlab::Serializer::Pagination.new(request, response) }
  end

  def itemized?
    @itemize
  end

  def paginated?
    @paginator.present?
  end

  def represent(resource, opts = {})
    resource = @paginator.paginate(resource) if paginated?

    if itemized?
      itemize(resource).map do |item|
        { name: item.name,
          size: item.size,
          latest: super(item.latest, opts) }
      end
    else
      super(resource, opts)
    end
  end

  private

  def itemize(resource)
    items = resource.group(:item_name).order('item_name ASC')
      .pluck('COALESCE(environment_type, name) AS item_name',
             'COUNT(*) AS environments_count',
             'MAX(id) AS last_environment_id')

    environments = resource.where(id: items.map(&:last)).index_by(&:id)

    items.map do |name, size, id|
      Item.new(name, size, environments[id])
    end
  end
end

class EnvironmentSerializer < BaseSerializer
  include WithPagination

  Item = Struct.new(:name, :size, :latest)

  entity EnvironmentEntity

  def within_folders
    tap { @itemize = true }
  end

  def itemized?
    @itemize
  end

  def represent(resource, opts = {})
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
    items = resource.order('folder ASC')
      .group('COALESCE(environment_type, name)')
      .select('COALESCE(environment_type, name) AS folder',
              'COUNT(*) AS size', 'MAX(id) AS last_id')

    # It makes a difference when you call `paginate` method, because
    # although `page` is effective at the end, it calls counting methods
    # immediately.
    items = @paginator.paginate(items) if paginated?

    environments = resource.where(id: items.map(&:last_id)).index_by(&:id)

    items.map do |item|
      Item.new(item.folder, item.size, environments[item.last_id])
    end
  end
end

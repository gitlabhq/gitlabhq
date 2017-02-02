class EnvironmentSerializer < BaseSerializer
  Struct.new('Item', :name, :size, :id, :latest)

  entity EnvironmentEntity

  def with_folders
    tap { @itemize = true }
  end

  def itemized?
    @itemize
  end

  def represent(resource, opts = {})
    # resource = paginate(resource) if paginated?

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

    environments = resource.where(id: items.map(&:last))

    items.zip(environments).map do |item|
      Struct::Item.new(*item.flatten)
    end
  end
end

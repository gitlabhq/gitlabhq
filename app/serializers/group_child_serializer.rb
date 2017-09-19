class GroupChildSerializer < BaseSerializer
  include WithPagination

  attr_reader :hierarchy_root, :should_expand_hierarchy

  entity GroupChildEntity

  def expand_hierarchy(hierarchy_root = nil)
    tap do
      @hierarchy_root = hierarchy_root
      @should_expand_hierarchy = true
    end
  end

  def represent(resource, opts = {}, entity_class = nil)
    if should_expand_hierarchy
      paginator.paginate(resource) if paginated?
      represent_hierarchies(resource, opts)
    else
      super(resource, opts)
    end
  end

  protected

  def represent_hierarchies(children, opts)
    if children.is_a?(GroupDescendant)
      represent_hierarchy(children.hierarchy(hierarchy_root), opts).first
    else
      hierarchies = Array.wrap(GroupDescendant.merge_hierarchies(children, hierarchy_root))
      hierarchies.map { |hierarchy| represent_hierarchy(hierarchy, opts) }.flatten
    end
  end

  def represent_hierarchy(hierarchy, opts)
    serializer = self.class.new(parameters)

    if hierarchy.is_a?(Hash)
      hierarchy.map do |parent, children|
        serializer.represent(parent, opts)
          .merge(children: Array.wrap(serializer.represent_hierarchy(children, opts)))
      end
    elsif hierarchy.is_a?(Array)
      hierarchy.map { |child| serializer.represent_hierarchy(child, opts) }
    else
      serializer.represent(hierarchy, opts)
    end
  end
end

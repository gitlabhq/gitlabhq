class GroupChildSerializer < BaseSerializer
  include WithPagination

  attr_reader :hierarchy_root, :should_expand_hierarchy

  entity GroupChildEntity

  def expand_hierarchy(hierarchy_root = nil)
    @hierarchy_root = hierarchy_root
    @should_expand_hierarchy = true

    self
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
      hierarchies = GroupDescendant.build_hierarchy(children, hierarchy_root)
      # When an array was passed, we always want to represent an array.
      # Even if the hierarchy only contains one element
      represent_hierarchy(Array.wrap(hierarchies), opts)
    end
  end

  def represent_hierarchy(hierarchy, opts)
    serializer = self.class.new(params)

    if hierarchy.is_a?(Hash)
      hierarchy.map do |parent, children|
        serializer.represent(parent, opts)
          .merge(children: Array.wrap(serializer.represent_hierarchy(children, opts)))
      end
    elsif hierarchy.is_a?(Array)
      hierarchy.flat_map { |child| serializer.represent_hierarchy(child, opts) }
    else
      serializer.represent(hierarchy, opts)
    end
  end
end

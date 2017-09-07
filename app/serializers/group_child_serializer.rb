class GroupChildSerializer < BaseSerializer
  include WithPagination

  attr_reader :hierarchy_root

  entity GroupChildEntity

  def expand_hierarchy(hierarchy_root)
    @hierarchy_root = hierarchy_root
    self
  end

  def represent(resource, opts = {}, entity_class = nil)
    if hierarchy_root.present?
      represent_hierarchies(resource, opts)
    else
      super(resource, opts)
    end
  end

  def represent_hierarchies(children, opts)
    if children.is_a?(GroupHierarchy)
      represent_hierarchy(children.hierarchy(hierarchy_root), opts)
    else
      children.map { |child| represent_hierarchy(child.hierarchy(hierarchy_root), opts) }
    end
  end

  def represent_hierarchy(hierarchy, opts)
    serializer = self.class.new(parameters)

    result = if hierarchy.is_a?(Hash)
               parent = hierarchy.keys.first
               serializer.represent(parent, opts)
                 .merge(children: [serializer.represent_hierarchy(hierarchy[parent], opts)])
             else
               serializer.represent(hierarchy, opts)
             end

    result
  end
end

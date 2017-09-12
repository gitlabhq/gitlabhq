class GroupChildSerializer < BaseSerializer
  include WithPagination

  attr_reader :hierarchy_root

  entity GroupChildEntity

  def expand_hierarchy(hierarchy_root = nil)
    @hierarchy_root = hierarchy_root
    @expand_hierarchy = true
    self
  end

  def represent(resource, opts = {}, entity_class = nil)
    if @expand_hierarchy
      represent_hierarchies(resource, opts)
    else
      super(resource, opts)
    end
  end

  protected

  def represent_hierarchies(children, opts)
    if children.is_a?(GroupHierarchy)
      represent_hierarchy(children.hierarchy(hierarchy_root), opts).first
    else
      hierarchies = Array.wrap(GroupHierarchy.merge_hierarchies(children, hierarchy_root))
      hierarchies.map { |hierarchy| represent_hierarchy(hierarchy, opts) }.flatten
    end
  end

  def represent_hierarchy(hierarchy, opts)
    serializer = self.class.new(parameters)

    result = if hierarchy.is_a?(Hash)
               hierarchy.map do |parent, children|
                 serializer.represent(parent, opts)
                   .merge(children: Array.wrap(serializer.represent_hierarchy(children, opts)))
               end
             else
               serializer.represent(hierarchy, opts)
             end

    result
  end
end

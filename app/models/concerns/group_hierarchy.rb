module GroupHierarchy
  def hierarchy(hierarchy_base = nil)
    @hierarchy ||= tree_for_child(self, self, hierarchy_base)
  end

  def parent
    if self.is_a?(Project)
      namespace
    else
      super
    end
  end

  def tree_for_child(child, tree, hierarchy_base)
    if child.parent.nil? && hierarchy_base.present?
      raise ArgumentError.new('specified base is not part of the tree')
    end

    if child.parent != hierarchy_base
      tree_for_child(child.parent,
                     { child.parent => tree },
                     hierarchy_base)
    else
      tree
    end
  end
end

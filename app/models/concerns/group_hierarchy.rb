module GroupHierarchy
  def hierarchy(hierarchy_base = nil)
    tree_for_child(self, self, hierarchy_base)
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

    if child.parent && child.parent != hierarchy_base
      tree_for_child(child.parent,
                     { child.parent => tree },
                     hierarchy_base)
    else
      tree
    end
  end

  def merge_hierarchy(other_element, hierarchy_base = nil)
    GroupHierarchy.merge_hierarchies([self, other_element], hierarchy_base)
  end

  def self.merge_hierarchies(hierarchies, hierarchy_base = nil)
    hierarchies = Array.wrap(hierarchies)
    return if hierarchies.empty?

    unless hierarchies.all? { |other_base| other_base.is_a?(GroupHierarchy) }
      raise ArgumentError.new('element is not a hierarchy')
    end

    first_hierarchy, *other_hierarchies = hierarchies
    merged = first_hierarchy.hierarchy(hierarchy_base)

    other_hierarchies.each do |child|
      next_hierarchy = child.hierarchy(hierarchy_base)
      merged = merge_values(merged, next_hierarchy)
    end

    merged
  end

  def self.merge_values(first_child, second_child)
    # When the first is an array, we need to go over every element to see if
    # we can merge deeper.
    if first_child.is_a?(Array)
      first_child.map do |element|
        if element.is_a?(Hash) && element.keys.any? { |k| second_child.keys.include?(k) }
          element.deep_merge(second_child) { |key, first, second| merge_values(first, second) }
        else
          element
        end
      end
    # If both of them are hashes, we can deep_merge with the same logic
    elsif first_child.is_a?(Hash) && second_child.is_a?(Hash)
      first_child.deep_merge(second_child) { |key, first, second| merge_values(first, second) }
    # If only one of them is a hash, we can check if the other child is already
    # included, we don't need to do anything when it is.
    elsif first_child.is_a?(Hash) && first_child.keys.include?(second_child)
      first_child
    elsif second_child.is_a?(Hash) && second_child.keys.include?(first_child)
      second_child
    else
      Array.wrap(first_child) + Array.wrap(second_child)
    end
  end
end

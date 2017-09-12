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

    unless hierarchies.all? { |hierarchy| hierarchy.is_a?(GroupHierarchy) }
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
    # we can merge deeper. If no match is found, we add the element to the array
    #
    # Handled cases:
    # [Array, Hash]
    if first_child.is_a?(Array) && second_child.is_a?(Hash)
      merge_hash_into_array(first_child, second_child)
    elsif first_child.is_a?(Hash) && second_child.is_a?(Array)
      merge_hash_into_array(second_child, first_child)
    # If both of them are hashes, we can deep_merge with the same logic
    #
    # Handled cases:
    # [Hash, Hash]
    elsif first_child.is_a?(Hash) && second_child.is_a?(Hash)
      first_child.deep_merge(second_child) { |key, first, second| merge_values(first, second) }
    # If only one of them is a hash, and one of them is a GroupHierachy-object
    # we can check if its already in the hash. If so, we don't need to do anything
    #
    # Handled cases
    # [Hash, GroupHierarchy]
    elsif first_child.is_a?(Hash) && first_child.keys.include?(second_child)
      first_child
    elsif second_child.is_a?(Hash) && second_child.keys.include?(first_child)
      second_child
    # If one or both elements are a GroupHierarchy, we wrap create an array
    # combining them.
    #
    # Handled cases:
    # [GroupHierarchy, Array], [GroupHierarchy, GroupHierarchy], [Array, Array]
    else
      Array.wrap(first_child) + Array.wrap(second_child)
    end
  end

  def self.merge_hash_into_array(array, new_hash)
    if mergeable_index = array.index { |element| element.is_a?(Hash) && (element.keys & new_hash.keys).any? }
      array[mergeable_index] = merge_values(array[mergeable_index], new_hash)
    else
      array << new_hash
    end

    array
  end
end

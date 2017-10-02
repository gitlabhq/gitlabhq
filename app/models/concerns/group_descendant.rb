module GroupDescendant
  def hierarchy(hierarchy_top = nil, preloaded = [])
    expand_hierarchy_for_child(self, self, hierarchy_top, preloaded)
  end

  def self.build_hierarchy(descendants, hierarchy_top = nil)
    descendants = Array.wrap(descendants)
    return if descendants.empty?

    unless descendants.all? { |hierarchy| hierarchy.is_a?(GroupDescendant) }
      raise ArgumentError.new('element is not a hierarchy')
    end

    first_descendant, *other_descendants = descendants
    merged = first_descendant.hierarchy(hierarchy_top, descendants)

    other_descendants.each do |descendant|
      next_descendant = descendant.hierarchy(hierarchy_top, descendants)
      merged = merge_hash_tree(merged, next_descendant)
    end

    merged
  end

  private

  def expand_hierarchy_for_child(child, hierarchy, hierarchy_top, preloaded = [])
    parent = preloaded.detect { |possible_parent| possible_parent.is_a?(Group) && possible_parent.id == child.parent_id }
    parent ||= child.parent

    if parent.nil? && hierarchy_top.present?
      raise ArgumentError.new('specified base is not part of the tree')
    end

    if parent && parent != hierarchy_top
      expand_hierarchy_for_child(parent,
                                 { parent => hierarchy },
                                 hierarchy_top,
                                 preloaded)
    else
      hierarchy
    end
  end

  private_class_method def self.merge_hash_tree(first_child, second_child)
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
      first_child.deep_merge(second_child) { |key, first, second| merge_hash_tree(first, second) }
    # If only one of them is a hash, and one of them is a GroupHierachy-object
    # we can check if its already in the hash. If so, we don't need to do anything
    #
    # Handled cases
    # [Hash, GroupDescendant]
    elsif first_child.is_a?(Hash) && first_child.keys.include?(second_child)
      first_child
    elsif second_child.is_a?(Hash) && second_child.keys.include?(first_child)
      second_child
    # If one or both elements are a GroupDescendant, we wrap create an array
    # combining them.
    #
    # Handled cases:
    # [GroupDescendant, Array], [GroupDescendant, GroupDescendant], [Array, Array]
    else
      Array.wrap(first_child) + Array.wrap(second_child)
    end
  end

  private_class_method def self.merge_hash_into_array(array, new_hash)
    if mergeable_index = array.index { |element| element.is_a?(Hash) && (element.keys & new_hash.keys).any? }
      array[mergeable_index] = merge_hash_tree(array[mergeable_index], new_hash)
    else
      array << new_hash
    end

    array
  end
end

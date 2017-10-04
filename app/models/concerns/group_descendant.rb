module GroupDescendant
  def hierarchy(hierarchy_top = nil, preloaded = nil)
    preloaded ||= ancestors_upto(hierarchy_top)
    expand_hierarchy_for_child(self, self, hierarchy_top, preloaded)
  end

  def self.build_hierarchy(descendants, hierarchy_top = nil)
    descendants = Array.wrap(descendants).uniq
    return [] if descendants.empty?

    unless descendants.all? { |hierarchy| hierarchy.is_a?(GroupDescendant) }
      raise ArgumentError.new('element is not a hierarchy')
    end

    all_hierarchies = descendants.map do |descendant|
      descendant.hierarchy(hierarchy_top, descendants)
    end

    Gitlab::Utils::MergeHash.merge(all_hierarchies)
  end

  private

  def ancestors_upto(hierarchy_top = nil)
    if hierarchy_top
      Gitlab::GroupHierarchy.new(Group.where(id: hierarchy_top)).base_and_descendants
    else
      Gitlab::GroupHierarchy.new(Group.where(id: self)).all_groups
    end
  end

  def expand_hierarchy_for_child(child, hierarchy, hierarchy_top, preloaded)
    parent = preloaded.detect { |possible_parent| possible_parent.is_a?(Group) && possible_parent.id == child.parent_id }
    parent ||= child.parent

    if parent.nil? && hierarchy_top.present?
      raise ArgumentError.new('specified top is not part of the tree')
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
end

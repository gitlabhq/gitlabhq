# frozen_string_literal: true

module GroupDescendant
  # Returns the hierarchy of a project or group in the from of a hash upto a
  # given top.
  #
  # > project.hierarchy
  # => { parent_group => { child_group => project } }
  def hierarchy(hierarchy_top = nil, preloaded = nil)
    preloaded ||= ancestors_upto(hierarchy_top)
    expand_hierarchy_for_child(self, self, hierarchy_top, preloaded)
  end

  # Merges all hierarchies of the given groups or projects into an array of
  # hashes. All ancestors need to be loaded into the given `descendants` to avoid
  # queries down the line.
  #
  # > GroupDescendant.merge_hierarchy([project, child_group, child_group2, parent])
  # => { parent => [{ child_group => project}, child_group2] }
  def self.build_hierarchy(descendants, hierarchy_top = nil)
    descendants = Array.wrap(descendants).uniq
    return [] if descendants.empty?

    unless descendants.all?(GroupDescendant)
      raise ArgumentError, _('element is not a hierarchy')
    end

    all_hierarchies = descendants.map do |descendant|
      descendant.hierarchy(hierarchy_top, descendants)
    end

    Gitlab::Utils::MergeHash.merge(all_hierarchies)
  end

  private

  def expand_hierarchy_for_child(child, hierarchy, hierarchy_top, preloaded)
    parent = hierarchy_top if hierarchy_top && child.parent_id == hierarchy_top.id
    parent ||= preloaded.detect do |possible_parent|
      possible_parent.is_a?(Group) && possible_parent.id == child.parent_id
    end

    if parent.nil? && !child.parent_id.nil?
      parent = child.parent

      exception = ArgumentError.new <<~MSG
        Parent was not preloaded for child when rendering group hierarchy.
        This error is not user facing, but causes a +1 query.
      MSG
      exception.set_backtrace(caller)

      extras = {
        parent: parent.inspect,
        child: child.inspect,
        preloaded: preloaded.map(&:full_path),
        issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/49404'
      }

      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(exception, extras)
    end

    if parent.nil? && hierarchy_top.present?
      raise ArgumentError, _('specified top is not part of the tree')
    end

    if parent && parent != hierarchy_top
      expand_hierarchy_for_child(parent, { parent => hierarchy }, hierarchy_top, preloaded)
    else
      hierarchy
    end
  end
end

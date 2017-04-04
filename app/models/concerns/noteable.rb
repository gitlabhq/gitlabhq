module Noteable
  def discussion_notes
    notes
  end

  delegate :find_discussion, to: :discussion_notes

  def discussions
    @discussions ||= discussion_notes
      .inc_relations_for_view
      .discussions(self)
  end

  def grouped_diff_discussions
    # Doesn't use `discussion_notes`, because this may include commit diff notes
    # besides MR diff notes, that we do no want to display on the MR Changes tab.
    notes.inc_relations_for_view.grouped_diff_discussions
  end

  def resolvable_discussions
    @resolvable_discussions ||= discussion_notes.resolvable.discussions(self)
  end

  def discussions_resolvable?
    resolvable_discussions.any?(&:resolvable?)
  end

  def discussions_resolved?
    discussions_resolvable? && resolvable_discussions.none?(&:to_be_resolved?)
  end

  def discussions_to_be_resolved?
    discussions_resolvable? && !discussions_resolved?
  end

  def discussions_to_be_resolved
    @discussions_to_be_resolved ||= resolvable_discussions.select(&:to_be_resolved?)
  end

  def discussions_can_be_resolved_by?(user)
    discussions_to_be_resolved.all? { |discussion| discussion.can_resolve?(user) }
  end
end

module Noteable
  # Names of all implementers of `Noteable` that support resolvable notes.
  RESOLVABLE_TYPES = %w(MergeRequest).freeze

  def base_class_name
    self.class.base_class.name
  end

  # Convert this Noteable class name to a format usable by notifications.
  #
  # Examples:
  #
  #   noteable.class           # => MergeRequest
  #   noteable.human_class_name # => "merge request"
  def human_class_name
    @human_class_name ||= base_class_name.titleize.downcase
  end

  def supports_resolvable_notes?
    RESOLVABLE_TYPES.include?(base_class_name)
  end

  def supports_discussions?
    DiscussionNote::NOTEABLE_TYPES.include?(base_class_name)
  end

  def discussions_rendered_on_frontend?
    false
  end

  def discussion_notes
    notes
  end

  delegate :find_discussion, to: :discussion_notes

  def discussions
    @discussions ||= discussion_notes
      .inc_relations_for_view
      .discussions(self)
  end

  def grouped_diff_discussions(*args)
    # Doesn't use `discussion_notes`, because this may include commit diff notes
    # besides MR diff notes, that we do not want to display on the MR Changes tab.
    notes.inc_relations_for_view.grouped_diff_discussions(*args)
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def resolvable_discussions
    @resolvable_discussions ||=
      if defined?(@discussions)
        @discussions.select(&:resolvable?)
      else
        discussion_notes.resolvable.discussions(self)
      end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

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

  def lockable?
    [MergeRequest, Issue].include?(self.class)
  end
end

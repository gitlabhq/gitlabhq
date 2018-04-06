# A note in a non-diff discussion on an issue, merge request, commit, or snippet.
#
# A note of this type can be resolvable.
class DiscussionNote < Note
  # Names of all implementers of `Noteable` that support discussions.
  NOTEABLE_TYPES = %w(MergeRequest Issue Commit Snippet Epic).freeze

  validates :noteable_type, inclusion: { in: NOTEABLE_TYPES }

  def discussion_class(*)
    Discussion
  end
end

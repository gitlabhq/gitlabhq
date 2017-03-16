class DiscussionNote < Note
  NOTEABLE_TYPES = %w(MergeRequest Issue Commit Snippet).freeze

  validates :noteable_type, inclusion: { in: NOTEABLE_TYPES }

  def discussion_class(*)
    SimpleDiscussion
  end
end

class DiscussionNote < Note
  NOTEABLE_TYPES = %w(MergeRequest).freeze

  validates :noteable_type, inclusion: { in: NOTEABLE_TYPES }

  def discussion_class(*)
    SimpleDiscussion
  end
end

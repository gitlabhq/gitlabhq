# A discussion to wrap a number of `Note` notes on the root of a commit when they
# are displayed in context of a merge request as if they were part of a discussion.
class OutOfContextDiscussion < Discussion
  # To make sure all out-of-context notes are displayed in one discussion,
  # we override the discussion ID to be a newly generated but consistent ID.
  def self.override_discussion_id(note)
    Digest::SHA1.hexdigest(build_discussion_id_base(note).join("-"))
  end

  # Keep this method in sync with the `potentially_resolvable` scope on `ResolvableNote`
  def potentially_resolvable?
    false
  end
end

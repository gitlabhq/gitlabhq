class CommitDiscussion < Discussion
  def self.override_discussion_id(note)
    discussion_id(note)
  end

  def potentially_resolvable?
    false
  end
end

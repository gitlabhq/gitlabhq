class SimpleDiscussion < Discussion
  def self.build_discussion_id(note)
    [*super(note), SecureRandom.hex]
  end

  def reply_attributes
    super.merge(discussion_id: self.id)
  end
end

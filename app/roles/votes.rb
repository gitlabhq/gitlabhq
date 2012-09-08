module Votes
  # Return the number of +1 comments (upvotes)
  def upvotes
    notes.select(&:upvote?).size
  end

  # Return the number of -1 comments (downvotes)
  def downvotes
    notes.select(&:downvote?).size
  end

  # Return the total number of votes
  def votes_count
    upvotes + downvotes
  end
end

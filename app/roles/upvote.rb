module Upvote
  # Return the number of +1 comments (upvotes)
  def upvotes
    notes.select(&:upvote?).size
  end
end

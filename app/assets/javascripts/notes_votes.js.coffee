class NotesVotes
  updateVotes: ->
    votes = $("#votes .votes")
    notes = $("#notes-list .note .vote")

    # only update if there is a vote display
    if votes.size()
      upvotes = notes.filter(".upvote").size()
      downvotes = notes.filter(".downvote").size()
      votesCount = upvotes + downvotes
      upvotesPercent = (if votesCount then (100.0 / votesCount * upvotes) else 0)
      downvotesPercent = (if votesCount then (100.0 - upvotesPercent) else 0)

      # change vote bar lengths
      votes.find(".bar-success").css "width", upvotesPercent + "%"
      votes.find(".bar-danger").css "width", downvotesPercent + "%"

      # replace vote numbers
      votes.find(".upvotes").text votes.find(".upvotes").text().replace(/\d+/, upvotes)
      votes.find(".downvotes").text votes.find(".downvotes").text().replace(/\d+/, downvotes)

@NotesVotes = NotesVotes

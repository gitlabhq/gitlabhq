# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.
module EE
  module SystemNoteService
    extend self

    # Called when the weight of a Noteable is changed
    #
    # noteable   - Noteable object
    # project    - Project owning noteable
    # author     - User performing the change
    #
    # Example Note text:
    #
    #   "removed the weight"
    #
    #   "changed weight to 4"
    #
    # Returns the created Note object

    def change_weight_note(noteable, project, author)
      body = noteable.weight ? "changed weight to **#{noteable.weight}**," : 'removed the weight'
      create_note(NoteSummary.new(noteable, project, author, body, action: 'weight'))
    end
  end
end

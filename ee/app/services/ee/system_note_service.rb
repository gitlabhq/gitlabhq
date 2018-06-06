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

    # Called when the start or end date of an Issuable is changed
    #
    # noteable   - Noteable object
    # author     - User performing the change
    # date_type  - 'start date' or 'finish date'
    # date       - New date
    #
    # Example Note text:
    #
    #   "changed start date to FIXME"
    #
    # Returns the created Note object
    def change_epic_date_note(noteable, author, date_type, date)
      body = if date
               "changed #{date_type} to #{date.strftime('%b %-d, %Y')}"
             else
               "removed the #{date_type}"
             end

      create_note(NoteSummary.new(noteable, nil, author, body, action: 'epic_date_changed'))
    end
  end
end

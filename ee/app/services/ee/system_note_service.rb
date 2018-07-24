# SystemNoteService
#
# Used for creating system notes (e.g., when a user references a merge request
# from an issue, an issue's assignee changes, an issue is closed, etc.
module EE
  module SystemNoteService
    extend self

    #
    # noteable     - Noteable object
    # noteable_ref - Referenced noteable object
    # user         - User performing reference
    #
    # Example Note text:
    #
    #   "marked this issue as related to gitlab-ce#9001"
    #
    # Returns the created Note object
    def relate_issue(noteable, noteable_ref, user)
      body = "marked this issue as related to #{noteable_ref.to_reference(noteable.project)}"

      create_note(NoteSummary.new(noteable, noteable.project, user, body, action: 'relate'))
    end

    #
    # noteable     - Noteable object
    # noteable_ref - Referenced noteable object
    # user         - User performing reference
    #
    # Example Note text:
    #
    #   "removed the relation with gitlab-ce#9001"
    #
    # Returns the created Note object
    def unrelate_issue(noteable, noteable_ref, user)
      body = "removed the relation with #{noteable_ref.to_reference(noteable.project)}"

      create_note(NoteSummary.new(noteable, noteable.project, user, body, action: 'unrelate'))
    end

    def epic_issue(epic, issue, user, type)
      return unless validate_epic_issue_action_type(type)

      action = type == :added ? 'epic_issue_added' : 'epic_issue_removed'

      body = "#{type} issue #{issue.to_reference(epic.group)}"

      create_note(NoteSummary.new(epic, nil, user, body, action: action))
    end

    def epic_issue_moved(from_epic, issue, to_epic, user)
      epic_issue_moved_act(from_epic, issue, to_epic, user, verb: 'added', direction: 'from')
      epic_issue_moved_act(to_epic, issue, from_epic, user, verb: 'moved', direction: 'to')
    end

    def epic_issue_moved_act(subject_epic, issue, object_epic, user, verb:, direction:)
      action = 'epic_issue_moved'

      body = "#{verb} issue #{issue.to_reference(subject_epic.group)} #{direction}" \
             " epic #{subject_epic.to_reference(object_epic.group)}"

      create_note(NoteSummary.new(object_epic, nil, user, body, action: action))
    end

    def issue_on_epic(issue, epic, user, type)
      return unless validate_epic_issue_action_type(type)

      if type == :added
        direction = 'to'
        action = 'issue_added_to_epic'
      else
        direction = 'from'
        action = 'issue_removed_from_epic'
      end

      body = "#{type} #{direction} epic #{epic.to_reference(issue.project)}"

      create_note(NoteSummary.new(issue, issue.project, user, body, action: action))
    end

    def issue_epic_change(issue, epic, user)
      body = "changed epic to #{epic.to_reference(issue.project)}"
      action = 'issue_changed_epic'

      create_note(NoteSummary.new(issue, issue.project, user, body, action: action))
    end

    def validate_epic_issue_action_type(type)
      [:added, :removed].include?(type)
    end

    # Called when the merge request is approved by user
    #
    # noteable - Noteable object
    # user     - User performing approve
    #
    # Example Note text:
    #
    #   "approved this merge request"
    #
    # Returns the created Note object
    def approve_mr(noteable, user)
      body = "approved this merge request"

      create_note(NoteSummary.new(noteable, noteable.project, user, body, action: 'approved'))
    end

    def unapprove_mr(noteable, user)
      body = "unapproved this merge request"

      create_note(NoteSummary.new(noteable, noteable.project, user, body, action: 'unapproved'))
    end

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
      body = noteable.weight ? "changed weight to **#{noteable.weight}**" : 'removed the weight'
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

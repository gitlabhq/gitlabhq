module EpicIssues
  class CreateService < IssuableLinks::CreateService
    def execute
      result = super
      issuable.update_start_and_due_dates
      result
    end

    private

    def relate_issues(referenced_issue)
      link = EpicIssue.find_or_initialize_by(issue: referenced_issue)

      params = if link.persisted?
                 { issue_moved: true, original_epic: link.epic }
               else
                 {}
               end

      link.epic = issuable
      link.move_to_start
      link.save!

      yield params
    end

    def create_notes(referenced_issue, params)
      if params[:issue_moved]
        SystemNoteService.epic_issue_moved(
          params[:original_epic], referenced_issue, issuable, current_user
        )
        SystemNoteService.issue_epic_change(referenced_issue, issuable, current_user)
      else
        SystemNoteService.epic_issue(issuable, referenced_issue, current_user, :added)
        SystemNoteService.issue_on_epic(referenced_issue, issuable, current_user, :added)
      end
    end

    def extractor_context
      { group: issuable.group }
    end

    def linkable_issues(issues)
      return [] unless can?(current_user, :admin_epic, issuable.group)

      issues.select { |issue| issuable_group_descendants.include?(issue.project.group) }
    end

    def issuable_group_descendants
      @descendants ||= issuable.group.self_and_descendants
    end
  end
end

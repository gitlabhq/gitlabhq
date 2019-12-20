# frozen_string_literal: true

module Issues
  class DuplicateService < Issues::BaseService
    def execute(duplicate_issue, canonical_issue)
      return if canonical_issue == duplicate_issue
      return unless can?(current_user, :update_issue, duplicate_issue)
      return unless can?(current_user, :create_note, canonical_issue)

      create_issue_duplicate_note(duplicate_issue, canonical_issue)
      create_issue_canonical_note(canonical_issue, duplicate_issue)

      close_service.new(project, current_user, {}).execute(duplicate_issue)
      duplicate_issue.update(duplicated_to: canonical_issue)
    end

    private

    def create_issue_duplicate_note(duplicate_issue, canonical_issue)
      SystemNoteService.mark_duplicate_issue(duplicate_issue, duplicate_issue.project, current_user, canonical_issue)
    end

    def create_issue_canonical_note(canonical_issue, duplicate_issue)
      SystemNoteService.mark_canonical_issue_of_duplicate(canonical_issue, canonical_issue.project, current_user, duplicate_issue)
    end
  end
end

Issues::DuplicateService.prepend_if_ee('EE::Issues::DuplicateService')

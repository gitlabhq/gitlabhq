module IssueLinks
  class DestroyService < BaseService
    def initialize(issue_link, user)
      @issue_link = issue_link
      @current_user = user
      @issue = issue_link.source
      @referenced_issue = issue_link.target
    end

    def execute
      remove_relation
      create_notes

      success(message: 'Relation was removed')
    end

    private

    def remove_relation
      @issue_link.destroy!
    end

    def create_notes
      SystemNoteService.unrelate_issue(@issue, @referenced_issue, current_user)
      SystemNoteService.unrelate_issue(@referenced_issue, @issue, current_user)
    end
  end
end

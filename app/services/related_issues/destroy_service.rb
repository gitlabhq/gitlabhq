module RelatedIssues
  class DestroyService < BaseService
    def initialize(related_issue, user)
      @related_issue = related_issue
      @current_user = user
      @issue = related_issue.issue
      @referenced_issue = related_issue.related_issue
    end

    def execute
      remove_relation!
      create_notes!

      success(message: 'Relation was removed')
    end

    private

    def remove_relation!
      @related_issue.destroy!
    end

    def create_notes!
      SystemNoteService.unrelate_issue(@issue, @referenced_issue, current_user)
      SystemNoteService.unrelate_issue(@referenced_issue, @issue, current_user)
    end
  end
end

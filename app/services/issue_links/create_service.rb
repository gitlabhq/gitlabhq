module IssueLinks
  class CreateService < BaseService
    def initialize(issue, user, params)
      @issue, @current_user, @params = issue, user, params.dup
    end

    def execute
      if referenced_issues.blank?
        return error('No Issue found for given reference', 401)
      end

      create_issue_link
      success
    end

    private

    def create_issue_link
      referenced_issues.each do |referenced_issue|
        create_notes(referenced_issue) if relate_issues(referenced_issue)
      end
    end

    def relate_issues(referenced_issue)
      IssueLink.create(source: @issue, target: referenced_issue)
    end

    def create_notes(referenced_issue)
      SystemNoteService.relate_issue(@issue, referenced_issue, current_user)
      SystemNoteService.relate_issue(referenced_issue, @issue, current_user)
    end

    def referenced_issues
      @referenced_issues ||= begin
        issue_references = params[:issue_references]
        text = issue_references.join(' ')

        extractor = Gitlab::ReferenceExtractor.new(@issue.project, @current_user)
        extractor.analyze(text)

        extractor.issues.select do |issue|
          can?(current_user, :admin_issue_link, issue.project)
        end
      end
    end
  end
end

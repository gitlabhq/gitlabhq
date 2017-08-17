module IssueLinks
  class CreateService < BaseService
    def initialize(issue, user, params)
      @issue, @current_user, @params = issue, user, params.dup
    end

    def execute
      if referenced_issues.blank?
        return error('No Issue found for given params', 404)
      end

      create_issue_links
      success
    end

    private

    def create_issue_links
      referenced_issues.each do |referenced_issue|
        create_notes(referenced_issue) if relate_issues(referenced_issue)
      end
    end

    # Returns a Boolean indicating if the Issue was related.
    def relate_issues(referenced_issue)
      IssueLink.new(source: @issue, target: referenced_issue).save
    end

    def create_notes(referenced_issue)
      SystemNoteService.relate_issue(@issue, referenced_issue, current_user)
      SystemNoteService.relate_issue(referenced_issue, @issue, current_user)
    end

    def referenced_issues
      @referenced_issues ||= begin
        target_issue = params[:target_issue]

        issues = if params[:issue_references].present?
                   extract_issues_from_references
                 elsif target_issue
                   [target_issue]
                 else
                   []
                 end

        issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
      end
    end

    def extract_issues_from_references
      issue_references = params[:issue_references]
      text = issue_references.join(' ')

      extractor = Gitlab::ReferenceExtractor.new(@issue.project, @current_user)
      extractor.analyze(text)

      extractor.issues
    end
  end
end

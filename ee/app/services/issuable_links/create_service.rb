module IssuableLinks
  class CreateService < BaseService
    attr_reader :issuable, :current_user, :params

    def initialize(issuable, user, params)
      @issuable, @current_user, @params = issuable, user, params.dup
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
        create_notes(referenced_issue) if relate_issues(referenced_issue) && create_notes?
      end
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

        linkable_issues(issues)
      end
    end

    def extract_issues_from_references
      issue_references = params[:issue_references]
      text = issue_references.join(' ')

      extractor = Gitlab::ReferenceExtractor.new(issuable.project, @current_user)
      extractor.analyze(text, extractor_context)

      extractor.issues
    end

    def create_notes(referenced_issue)
      SystemNoteService.relate_issue(issuable, referenced_issue, current_user)
      SystemNoteService.relate_issue(referenced_issue, issuable, current_user)
    end

    def extractor_context
      {}
    end

    def create_notes?
      true
    end

    def linkable_issues(issues)
      raise NotImplementedError
    end

    def relate_issues(referenced_issue)
      raise NotImplementedError
    end
  end
end

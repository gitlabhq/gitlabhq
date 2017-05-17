module RelatedIssues
  class CreateService < BaseService
    def initialize(issue, user, params)
      @issue, @current_user, @params = issue, user, params.dup
    end

    def execute
      if referenced_issues.blank?
        return error('No Issue found for given reference', 401)
      end

      create_related_issues!

      success_message
    rescue => exception
      error(exception.message, 401)
    end

    private

    def create_related_issues!
      RelatedIssue.transaction do
        referenced_issues.each do |referenced_issue|
          relate_issues!(referenced_issue)
          create_notes!(referenced_issue)
        end
      end
    end

    def relate_issues!(referenced_issue)
      RelatedIssue.create!(issue: @issue, related_issue: referenced_issue)
    end

    def create_notes!(referenced_issue)
      SystemNoteService.relate_issue(@issue, referenced_issue, current_user)
      SystemNoteService.relate_issue(referenced_issue, @issue, current_user)
    end

    def referenced_issues
      @referenced_issues ||= begin
        issue_references = params[:issue_references]
        text = issue_references.join(' ')

        extractor = Gitlab::ReferenceExtractor.new(@issue.project, @current_user)
        extractor.analyze(text)

        extractor.issues
      end
    end

    def success_message
      verb = referenced_issues.size > 1 ? 'were' : 'was'

      success(message: "#{issues_sentence(referenced_issues)} #{verb} successfully related")
    end

    def issues_sentence(issues)
      issues.map { |issue| issue.to_reference(@issue.project) }.sort.to_sentence
    end
  end
end

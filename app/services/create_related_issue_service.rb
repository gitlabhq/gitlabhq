class CreateRelatedIssueService < BaseService
  def initialize(issue, user, params)
    @issue, @current_user, @params = issue, user, params.dup
  end

  def execute
    if referenced_issues.blank?
      return error('No Issue found for given reference', 401)
    end

    begin
      create_related_issues!
    rescue => exception
      return error(exception.message, 401)
    end

    success(message: "#{issues_sentence(referenced_issues)} were successfully related")
  end

  private

  def create_related_issues!
    RelatedIssue.transaction do
      referenced_issues.each do |referenced_issue|
        RelatedIssue.create!(issue: @issue, related_issue: referenced_issue)
      end
    end
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

  def issues_sentence(issues)
    issues.map { |issue| issue.to_reference(@issue.project) }.sort.to_sentence
  end
end

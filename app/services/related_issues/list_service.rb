module RelatedIssues
  class ListService
    include Gitlab::Routing

    def initialize(issue, user)
      @issue, @current_user = issue, user
    end

    def execute
      related_issues.map do |related_issue|
        referenced_issue =
          if related_issue.related_issue == @issue
            related_issue.issue
          else
            related_issue.related_issue
          end

        {
          title: referenced_issue.title,
          state: referenced_issue.state,
          reference: referenced_issue.to_reference(@issue.project),
          path: namespace_project_issue_path(referenced_issue.project.namespace, referenced_issue.project, referenced_issue.iid)
        }
      end
    end

    private

    def related_issues
      RelatedIssue
        .where("issue_id = #{@issue.id} OR related_issue_id = #{@issue.id}")
        .preload(related_issue: :project, issue: :project)
        .order(:created_at)
    end
  end
end
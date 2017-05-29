module IssueLinks
  class ListService
    include Gitlab::Routing

    def initialize(issue, user)
      @issue, @current_user, @project = issue, user, issue.project
    end

    def execute
      issues.map do |referenced_issue|
        {
          id: referenced_issue.id,
          iid: referenced_issue.iid,
          title: referenced_issue.title,
          state: referenced_issue.state,
          project_path: referenced_issue.project.path,
          namespace_full_path: referenced_issue.project.namespace.full_path,
          path: namespace_project_issue_path(referenced_issue.project.namespace, referenced_issue.project, referenced_issue.iid),
          destroy_relation_path: destroy_relation_path(referenced_issue)
        }
      end
    end

    private

    def issues
      return @issues if defined?(@issues)

      authorized_issues = IssuesFinder.new(@current_user, project_id: @project.id).execute
      referenced_issues = @issue.referenced_issues.select('issues.*', 'issue_links.id AS issue_links_id')
      referred_by_issues = @issue.referred_by_issues.select('issues.*', 'issue_links.id AS issue_links_id')

      union = Gitlab::SQL::Union.new([referenced_issues, referred_by_issues])

      @issues = Issue.from("(#{union.to_sql}) #{Issue.table_name}")
                     .where(id: authorized_issues.select(:id))
                     .preload(project: :namespace)
                     .reorder('issue_links_id')
    end

    def destroy_relation_path(issue)
      if can_destroy_issue_link_on_current_project? && can_destroy_issue_link?(issue.project)
        namespace_project_issue_link_path(issue.project.namespace,
                                          issue.project,
                                          issue.iid,
                                          issue.issue_links_id)
      end
    end

    def can_destroy_issue_link_on_current_project?
      @can_destroy_on_current_project ||= can_destroy_issue_link?(@project)
    end

    def can_destroy_issue_link?(project)
      Ability.allowed?(@current_user, :admin_issue_link, project)
    end
  end
end

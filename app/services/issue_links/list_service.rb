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

      # TODO: Simplify query using AR
      @issues = Issue.find_by_sql(
        <<-SQL.strip_heredoc
          SELECT issues.*, issue_links.id as issue_links_id FROM issues
          INNER JOIN issue_links ON issue_links.target_id = issues.id
          WHERE issue_links.source_id = #{@issue.id} AND issues.deleted_at IS NULL
          UNION ALL
          SELECT issues.*, issue_links.id as issue_links_id FROM issues
          INNER JOIN issue_links ON issue_links.source_id = issues.id
          WHERE issue_links.target_id = #{@issue.id} AND issues.deleted_at IS NULL
          ORDER BY issue_links_id
        SQL
      )

      # TODO: Try to use SQL instead Array#select
      @issues = Ability.issues_readable_by_user(@issues, @current_user)
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

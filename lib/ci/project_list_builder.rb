module Ci
  class ProjectListBuilder
    def execute(current_user, search = nil)
      projects = current_user.authorized_projects
      projects = projects.search(search) if search
      
      projects.
        joins("LEFT JOIN ci_projects ON projects.id = ci_projects.gitlab_id
          LEFT JOIN #{last_commit_subquery} AS last_commit ON #{Ci::Project.table_name}.id = last_commit.project_id").
        reorder("ci_projects.id is NULL ASC,
          CASE WHEN last_commit.committed_at IS NULL THEN 1 ELSE 0 END,
          last_commit.committed_at DESC")
    end

    private

    def last_commit_subquery
      "(SELECT project_id, MAX(committed_at) committed_at FROM #{Ci::Commit.table_name} GROUP BY project_id)"
    end
  end
end

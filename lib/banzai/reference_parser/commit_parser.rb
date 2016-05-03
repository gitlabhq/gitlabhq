module Banzai
  module ReferenceParser
    class CommitParser < Parser
      self.reference_type = :commit

      def referenced_by(nodes)
        commit_ids = commit_ids_per_project(nodes)
        projects = find_projects(commit_ids.keys)
        commits = []

        projects.each do |project|
          next unless project.valid_repo?

          commits.concat(find_commits(project, commit_ids[project.id]))
        end

        commits
      end

      def commit_ids_per_project(nodes)
        gather_attributes_per_project(nodes, 'data-commit')
      end

      def find_commits(project, ids)
        commits = []

        ids.each do |id|
          commit = project.commit(id)

          commits << commit if commit
        end

        commits
      end

      def find_projects(ids)
        Project.where(id: ids)
      end
    end
  end
end

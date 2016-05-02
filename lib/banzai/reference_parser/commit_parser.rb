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
        commit_ids = Hash.new { |hash, key| hash[key] = Set.new }

        nodes.each do |node|
          project_id = node.attr('data-project').to_i
          id = node.attr('data-commit')

          commit_ids[project_id] << id if id
        end

        commit_ids
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

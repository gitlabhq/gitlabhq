# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class CommitParser < BaseParser
      self.reference_type = :commit

      def referenced_by(nodes, options = {})
        commit_ids = commit_ids_per_project(nodes)
        projects = find_projects_for_hash_keys(commit_ids)

        projects.flat_map do |project|
          find_commits(project, commit_ids[project.id])
        end
      end

      def commit_ids_per_project(nodes)
        gather_attributes_per_project(nodes, self.class.data_attribute)
      end

      def find_commits(project, ids)
        commits = []

        return commits unless project.valid_repo?

        ids.each do |id|
          commit = project.commit(id)

          commits << commit if commit
        end

        commits
      end

      private

      def can_read_reference?(user, ref_project, node)
        can?(user, :download_code, ref_project)
      end
    end
  end
end

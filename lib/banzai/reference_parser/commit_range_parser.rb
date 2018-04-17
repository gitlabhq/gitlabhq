module Banzai
  module ReferenceParser
    class CommitRangeParser < BaseParser
      self.reference_type = :commit_range

      def referenced_by(nodes)
        range_ids = commit_range_ids_per_project(nodes)
        projects = find_projects_for_hash_keys(range_ids)

        projects.flat_map do |project|
          find_ranges(project, range_ids[project.id])
        end
      end

      def commit_range_ids_per_project(nodes)
        gather_attributes_per_project(nodes, self.class.data_attribute)
      end

      def find_ranges(project, range_ids)
        ranges = []

        range_ids.each do |id|
          range = find_object(project, id)

          ranges << range if range
        end

        ranges
      end

      def find_object(project, id)
        return unless project.is_a?(Project)

        range = CommitRange.new(id, project)

        range.valid_commits? ? range : nil
      end

      private

      def can_read_reference?(user, ref_project, node)
        can?(user, :download_code, ref_project)
      end
    end
  end
end

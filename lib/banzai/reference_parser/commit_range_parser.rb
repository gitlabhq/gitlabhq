module Banzai
  module ReferenceParser
    class CommitRangeParser < Parser
      self.reference_type = :commit_range

      def referenced_by(nodes)
        range_ids = commit_range_ids_per_project(nodes)
        projects = find_projects(range_ids.keys)
        ranges = []

        projects.each do |project|
          ranges.concat(find_ranges(project, range_ids[project.id]))
        end

        ranges
      end

      def commit_range_ids_per_project(nodes)
        range_ids = Hash.new { |hash, key| hash[key] = Set.new }

        nodes.each do |node|
          project_id = node.attr('data-project').to_i
          id = node.attr('data-commit-range')

          range_ids[project_id] << id if id
        end

        range_ids
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
        range = CommitRange.new(id, project)

        range.valid_commits? ? range : nil
      end

      def find_projects(ids)
        Project.where(id: ids)
      end
    end
  end
end

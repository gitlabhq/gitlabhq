module Banzai
  module ReferenceParser
    class CommitRangeParser < Parser
      self.reference_type = :commit_range

      def referenced_by(node)
        project = Project.find_by(id: node.attr("data-project"))

        return [] unless project

        id = node.attr("data-commit-range")

        return [] if id.blank?

        object = find_object(project, id)

        object ? [object] : []
      end

      def find_object(project, id)
        range = CommitRange.new(id, project)

        range.valid_commits? ? range : nil
      end
    end
  end
end

module Banzai
  module ReferenceParser
    class CommitParser < Parser
      self.reference_type = :commit

      def referenced_by(node)
        project = Project.find_by(id: node.attr("data-project"))

        return [] unless project

        id = node.attr("data-commit")

        return [] if id.blank?

        object = find_object(project, id)

        object ? [object] : []
      end

      def find_object(project, id)
        if project.valid_repo?
          project.commit(id)
        else
          nil
        end
      end
    end
  end
end

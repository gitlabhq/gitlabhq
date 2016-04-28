module Banzai
  module ReferenceParser
    class ExternalIssueParser < Parser
      self.reference_type = :external_issue

      def referenced_by(node)
        project = Project.find_by(id: node.attr("data-project"))

        return [] unless project

        id = node.attr("data-external-issue")

        return [] if id.blank?

        [ExternalIssue.new(id, project)]
      end
    end
  end
end

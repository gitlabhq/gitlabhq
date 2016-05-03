module Banzai
  module ReferenceParser
    class ExternalIssueParser < Parser
      self.reference_type = :external_issue

      def referenced_by(nodes)
        issue_ids = issue_ids_per_project(nodes)
        projects = find_projects(issue_ids.keys)
        issues = []

        projects.each do |project|
          issue_ids[project.id].each do |id|
            issues << ExternalIssue.new(id, project)
          end
        end

        issues
      end

      def issue_ids_per_project(nodes)
        gather_attributes_per_project(nodes, 'data-external-issue')
      end

      def find_projects(ids)
        Project.where(id: ids)
      end
    end
  end
end

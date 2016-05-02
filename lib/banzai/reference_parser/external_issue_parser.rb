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
        issue_ids = Hash.new { |hash, key| hash[key] = Set.new }

        nodes.each do |node|
          project_id = node.attr('data-project').to_i
          id = node.attr('data-external-issue')

          issue_ids[project_id] << id if id
        end

        issue_ids
      end

      def find_projects(ids)
        Project.where(id: ids)
      end
    end
  end
end

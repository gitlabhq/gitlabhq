module Banzai
  module ReferenceParser
    class ExternalIssueParser < BaseParser
      self.reference_type = :external_issue

      def referenced_by(nodes)
        issue_ids = issue_ids_per_project(nodes)
        projects = find_projects_for_hash_keys(issue_ids)
        issues = []

        projects.each do |project|
          issue_ids[project.id].each do |id|
            issues << ExternalIssue.new(id, project)
          end
        end

        issues
      end

      def issue_ids_per_project(nodes)
        gather_attributes_per_project(nodes, self.class.data_attribute)
      end

      private

      def can_read_reference?(user, ref_project)
        can?(user, :read_issue, ref_project)
      end
    end
  end
end

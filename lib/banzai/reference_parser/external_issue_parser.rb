# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class ExternalIssueParser < BaseParser
      self.reference_type = :external_issue

      def referenced_by(nodes, options = {})
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

      # we extract only external issue trackers references here, we don't extract cross-project references,
      # so we don't need to do anything here.
      def can_read_reference?(user, ref_project, node)
        true
      end

      def nodes_visible_to_user(user, nodes)
        nodes
      end
    end
  end
end

# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class MergeRequestParser < IssuableParser
      include Gitlab::Utils::StrongMemoize

      self.reference_type = :merge_request

      def nodes_visible_to_user(user, nodes)
        return super if Feature.disabled?(:optimize_merge_request_parser, user, default_enabled: :yaml)

        merge_request_nodes = nodes.select { |node| node.has_attribute?(self.class.data_attribute) }
        records = projects_for_nodes(merge_request_nodes)

        merge_request_nodes.select do |node|
          project = records[node]

          project && can_read_reference?(user, project)
        end
      end

      def records_for_nodes(nodes)
        @merge_requests_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          MergeRequest.includes(
            :author,
            :assignees,
            {
              # These associations are primarily used for checking permissions.
              # Eager loading these ensures we don't end up running dozens of
              # queries in this process.
              target_project: [{ namespace: :route }, :project_feature, :route]
            }),
          self.class.data_attribute
        )
      end

      def can_read_reference?(user, object)
        memo = strong_memoize(:can_read_reference) { {} }

        project_id = object.project_id

        return memo[project_id] if memo.key?(project_id)

        memo[project_id] = can?(user, :read_merge_request_iid, object)
      end

      def projects_for_nodes(nodes)
        @projects_for_nodes ||=
          grouped_objects_for_nodes(nodes, Project.includes(:project_feature, :group, :namespace), 'data-project')
      end
    end
  end
end

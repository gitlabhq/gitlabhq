module Banzai
  module ReferenceParser
    class MergeRequestParser < BaseParser
      self.reference_type = :merge_request

      def nodes_visible_to_user(user, nodes)
        merge_requests = merge_requests_for_nodes(nodes)

        nodes.select do |node|
          merge_request = merge_requests[node]

          merge_request && can?(user, :read_merge_request, merge_request.project)
        end
      end

      def referenced_by(nodes)
        merge_requests = merge_requests_for_nodes(nodes)

        nodes.map { |node| merge_requests[node] }.compact.uniq
      end

      def merge_requests_for_nodes(nodes)
        @merge_requests_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          MergeRequest.includes(
            :author,
            :assignee,
            {
              # These associations are primarily used for checking permissions.
              # Eager loading these ensures we don't end up running dozens of
              # queries in this process.
              target_project: [
                { namespace: :owner },
                { group: [:owners, :group_members] },
                :invited_groups,
                :project_members,
                :project_feature
              ]
            }),
          self.class.data_attribute
        )
      end

      def can_read_reference?(user, ref_project, node)
        can?(user, :read_merge_request, ref_project)
      end
    end
  end
end

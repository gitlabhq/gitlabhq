module Banzai
  module ReferenceParser
    class MergeRequestParser < BaseParser
      self.reference_type = :merge_request

      def merge_requests_for_nodes(nodes)
        @merge_requests_for_nodes ||= grouped_objects_for_nodes(
          nodes,
          MergeRequest.all,
          self.class.data_attribute
        )
      end

      def references_relation
        MergeRequest.includes(:author, :assignee, :target_project)
      end

      private

      def can_read_reference?(user, ref_project, node)
        can?(user, :read_merge_request, ref_project)
      end
    end
  end
end

module Banzai
  module ReferenceParser
    class MergeRequestParser < BaseParser
      self.reference_type = :merge_request

      def references_relation
        MergeRequest.includes(:author, :assignee, :target_project)
      end

      private

      def can_read_reference?(user, ref_project)
        can?(user, :read_merge_request, ref_project)
      end
    end
  end
end

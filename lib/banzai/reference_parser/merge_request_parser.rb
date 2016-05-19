module Banzai
  module ReferenceParser
    class MergeRequestParser < Parser
      self.reference_type = :merge_request

      def references_relation
        MergeRequest.includes(:author, :assignee, :target_project)
      end
    end
  end
end

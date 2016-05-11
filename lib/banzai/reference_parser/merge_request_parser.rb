module Banzai
  module ReferenceParser
    class MergeRequestParser < Parser
      self.reference_type = :merge_request

      def referenced_by(nodes)
        ids = nodes.map { |node| node.attr('data-merge-request') }

        MergeRequest.includes(:author, :assignee, :target_project).
          where(id: ids)
      end
    end
  end
end

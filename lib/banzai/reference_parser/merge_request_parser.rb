module Banzai
  module ReferenceParser
    class MergeRequestParser < Parser
      self.reference_type = :merge_request

      def referenced_by(node)
        [LazyReference.new(MergeRequest, node.attr('data-merge-request'))]
      end
    end
  end
end

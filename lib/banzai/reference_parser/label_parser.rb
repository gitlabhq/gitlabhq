module Banzai
  module ReferenceParser
    class LabelParser < Parser
      self.reference_type = :label

      def references_relation
        Label
      end
    end
  end
end

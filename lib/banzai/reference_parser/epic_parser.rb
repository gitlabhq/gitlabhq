# for CE this is here only to make sure no other reference will use '&' as a prefix'
module Banzai
  module ReferenceParser
    class EpicParser < BaseParser
      self.reference_type = :epic

      def references_relation
        Epic
      end
    end
  end
end

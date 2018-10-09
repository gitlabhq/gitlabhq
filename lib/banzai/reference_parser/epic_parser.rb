# frozen_string_literal: true

module Banzai
  module ReferenceParser
    # The actual parser is implemented in the EE mixin
    class EpicParser < IssuableParser
      prepend ::EE::Banzai::ReferenceParser::EpicParser

      self.reference_type = :epic

      def records_for_nodes(_nodes)
        {}
      end
    end
  end
end

# frozen_string_literal: true

module Banzai
  module ReferenceParser
    # The actual parser is implemented in the EE mixin
    class IterationParser < BaseParser
      self.reference_type = :iteration

      def references_relation
        Iteration
      end

      private

      def can_read_reference?(_user, _ref_project, _node)
        false
      end
    end
  end
end

Banzai::ReferenceParser::IterationParser.prepend_mod_with('Banzai::ReferenceParser::IterationParser')

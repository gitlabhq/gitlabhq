# frozen_string_literal: true

module Banzai
  module Filter
    # The actual filter is implemented in the EE mixin
    class IterationReferenceFilter < AbstractReferenceFilter
      self.reference_type = :iteration

      def self.object_class
        Iteration
      end
    end
  end
end

Banzai::Filter::IterationReferenceFilter.prepend_if_ee('EE::Banzai::Filter::IterationReferenceFilter')

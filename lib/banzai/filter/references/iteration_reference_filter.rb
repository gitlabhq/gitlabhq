# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # The actual filter is implemented in the EE mixin
      class IterationReferenceFilter < AbstractReferenceFilter
        self.reference_type = :iteration
        self.object_class   = Iteration
      end
    end
  end
end

Banzai::Filter::References::IterationReferenceFilter.prepend_if_ee('EE::Banzai::Filter::References::IterationReferenceFilter')

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

Banzai::Filter::References::IterationReferenceFilter.prepend_mod_with('Banzai::Filter::References::IterationReferenceFilter')

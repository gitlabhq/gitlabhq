# frozen_string_literal: true

module Banzai
  module Filter
    module References
      # The actual filter is implemented in the EE mixin
      class EpicReferenceFilter < IssuableReferenceFilter
        self.reference_type = :epic

        def self.object_class
          Epic
        end

        private

        def group
          context[:group] || context[:project]&.group
        end
      end
    end
  end
end

Banzai::Filter::References::EpicReferenceFilter.prepend_mod_with('Banzai::Filter::References::EpicReferenceFilter')

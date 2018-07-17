module EE
  module Banzai
    module Pipeline
      module SingleLinePipeline
        extend ActiveSupport::Concern

        class_methods do
          def reference_filters
            [
              ::Banzai::Filter::EpicReferenceFilter,
              *super
            ]
          end
        end
      end
    end
  end
end

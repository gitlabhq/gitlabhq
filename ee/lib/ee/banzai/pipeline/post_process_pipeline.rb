module EE
  module Banzai
    module Pipeline
      module PostProcessPipeline
        extend ActiveSupport::Concern

        class_methods do
          def internal_link_filters
            [
              *super,
              ::Banzai::Filter::CrossProjectIssuableInformationFilter
            ]
          end
        end
      end
    end
  end
end

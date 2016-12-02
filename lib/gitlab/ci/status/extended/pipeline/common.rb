module Gitlab::Ci
  module Status
    module Extended
      module Pipeline
        module Common
          def initialize(pipeline)
            @pipeline = pipeline
          end

          def has_details?
            true
          end

          def details_path
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end

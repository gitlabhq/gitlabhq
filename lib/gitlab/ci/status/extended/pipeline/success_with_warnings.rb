module Gitlab::Ci
  module Status
    module Extended
      module Pipeline
        class SuccessWithWarnings < SimpleDelegator
          extend Status::Extended::Base

          def label
            'passed with warnings'
          end

          def icon
            'icon_status_warning'
          end

          def self.matches?(pipeline)
            pipeline.success? && pipeline.has_warnings?
          end
        end
      end
    end
  end
end

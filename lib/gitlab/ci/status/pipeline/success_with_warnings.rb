module Gitlab
  module Ci
    module Status
      module Pipeline
        class SuccessWithWarnings < SimpleDelegator
          extend Status::Extended

          def text
            'passed'
          end

          def label
            'passed with warnings'
          end

          def icon
            'icon_status_warning'
          end

          def to_s
            'success_with_warnings'
          end

          def self.matches?(pipeline)
            pipeline.success? && pipeline.has_warnings?
          end
        end
      end
    end
  end
end

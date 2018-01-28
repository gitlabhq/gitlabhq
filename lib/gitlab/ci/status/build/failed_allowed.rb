module Gitlab
  module Ci
    module Status
      module Build
        class FailedAllowed < Status::Extended
          def label
            'failed (allowed to fail)'
          end

          def icon
            'status_warning'
          end

          def group
            'failed_with_warnings'
          end

          def self.matches?(build, user)
            build.failed? && build.allow_failure?
          end
        end
      end
    end
  end
end

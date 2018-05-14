module Gitlab
  module Ci
    module Status
      module Build
        class FailedAllowed < Status::Extended
          def label
            "failed #{allowed_to_fail_title}"
          end

          def icon
            'status_warning'
          end

          def group
            'failed_with_warnings'
          end

          def status_tooltip
            "#{@status.status_tooltip} #{allowed_to_fail_title}"
          end

          def self.matches?(build, user)
            build.failed? && build.allow_failure?
          end

          private

          def allowed_to_fail_title
            "(allowed to fail)"
          end
        end
      end
    end
  end
end

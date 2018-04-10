module Gitlab
  module Ci
    module Status
      module Build
        class Empty < Status::Extended
          def illustration
            {
              image: 'illustrations/skipped-job_empty.svg',
              size: 'svg-430',
              title: _('This job does not have a trace.')
            }
          end

          def self.matches?(build, user)
            !build.has_trace?
          end
        end
      end
    end
  end
end

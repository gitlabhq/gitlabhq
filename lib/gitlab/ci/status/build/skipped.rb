module Gitlab
  module Ci
    module Status
      module Build
        class Skipped < Status::Extended
          def illustration
            {
              image: 'illustrations/skipped-job_empty.svg',
              size: 'svg-430',
              title: _('This job has been skipped')
            }
          end

          def self.matches?(build, user)
            build.skipped?
          end
        end
      end
    end
  end
end

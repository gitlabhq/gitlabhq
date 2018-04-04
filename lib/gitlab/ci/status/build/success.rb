module Gitlab
  module Ci
    module Status
      module Build
        class Success < Status::Extended
          def illustration
            {
              image: 'illustrations/skipped-job_empty.svg',
              size: 'svg-430',
              title: _('Job has been erased')
            }
          end

          def self.matches?(build, user)
            build.success?
          end
        end
      end
    end
  end
end

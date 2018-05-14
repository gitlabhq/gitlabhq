module Gitlab
  module Ci
    module Status
      module Build
        class Created < Status::Extended
          def illustration
            {
              image: 'illustrations/job_not_triggered.svg',
              size: 'svg-306',
              title: _('This job has not been triggered yet'),
              content: _('This job depends on upstream jobs that need to succeed in order for this job to be triggered')
            }
          end

          def self.matches?(build, user)
            build.created?
          end
        end
      end
    end
  end
end

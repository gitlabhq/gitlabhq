module Gitlab
  module Ci
    module Status
      module Build
        class Pending < Status::Extended
          def illustration
            {
              image: 'illustrations/pending_job_empty.svg',
              size: 'svg-430',
              title: _('This job has not started yet'),
              content: _('This job is in pending state and is waiting to be picked by a runner')
            }
          end

          def self.matches?(build, user)
            build.pending?
          end
        end
      end
    end
  end
end

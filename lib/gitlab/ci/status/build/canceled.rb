module Gitlab
  module Ci
    module Status
      module Build
        class Canceled < Status::Extended
          def illustration
            {
              image: 'illustrations/canceled-job_empty.svg',
              size: 'svg-430',
              title: _('This job has been canceled')
            }
          end

          def self.matches?(build, user)
            build.canceled?
          end
        end
      end
    end
  end
end

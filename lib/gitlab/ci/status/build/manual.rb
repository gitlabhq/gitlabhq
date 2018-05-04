module Gitlab
  module Ci
    module Status
      module Build
        class Manual < Status::Extended
          def illustration
            {
              image: 'illustrations/manual_action.svg',
              size: 'svg-394',
              title: _('This job requires a manual action'),
              content: _('This job depends on a user to trigger its process. Often they are used to deploy code to production environments')
            }
          end

          def self.matches?(build, user)
            build.playable?
          end
        end
      end
    end
  end
end

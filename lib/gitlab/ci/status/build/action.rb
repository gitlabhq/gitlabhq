module Gitlab
  module Ci
    module Status
      module Build
        ##
        # Extended status for playable manual actions.
        #
        class Action < Status::Extended
          def label
            if has_action?
              @status.label
            else
              "#{@status.label} (not allowed)"
            end
          end

          def illustration
            {
              image: 'illustrations/manual_action.svg',
              size: 'svg-394',
              title: _('This job requires a manual action'),
              content: _('This job depends on a user to trigger its process. Often they are used to deploy code to production environments'),
              action_path: action_path,
              action_method: action_method
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

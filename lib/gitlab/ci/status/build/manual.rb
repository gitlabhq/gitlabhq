# frozen_string_literal: true

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
              content: _('This job requires manual intervention to start. Before starting this job, you can add variables below for last-minute configuration changes.')
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

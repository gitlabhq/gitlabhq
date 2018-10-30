# frozen_string_literal: true

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

          def self.matches?(build, user)
            build.playable?
          end
        end
      end
    end
  end
end

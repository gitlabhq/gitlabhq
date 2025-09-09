# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        ##
        # Extended status used when the bridge has strategy: mirror.
        # This will allow the status to be mirrored from the downstream pipeline status.
        #
        class SuccessWarning < Status::Extended
          def self.matches?(bridge, _user)
            bridge.success? && bridge.mirrored? && bridge.downstream_pipeline&.has_warnings?
          end

          def icon
            'status_warning'
          end

          def group
            'success-with-warnings'
          end

          def label
            s_('CiStatusLabel|success with warnings')
          end

          def status_tooltip
            "#{@status.status_tooltip} (success with warnings)"
          end
        end
      end
    end
  end
end

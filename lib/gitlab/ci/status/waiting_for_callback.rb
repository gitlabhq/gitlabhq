# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class WaitingForCallback < Status::Core
        def text
          s_('CiStatusText|Waiting')
        end

        def label
          s_('CiStatusLabel|waiting for callback')
        end

        def icon
          'status_pending'
        end

        def favicon
          'favicon_status_pending'
        end

        def group
          'waiting-for-callback'
        end

        def details_path
          nil
        end
      end
    end
  end
end

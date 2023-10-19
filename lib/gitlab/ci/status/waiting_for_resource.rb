# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class WaitingForResource < Status::Core
        def text
          s_('CiStatusText|Waiting')
        end

        def label
          s_('CiStatusLabel|waiting for resource')
        end

        def icon
          'status_pending'
        end

        def favicon
          'favicon_status_pending'
        end

        def name
          'WAITING_FOR_RESOURCE'
        end

        def group
          'waiting-for-resource'
        end

        def details_path
          nil
        end
      end
    end
  end
end

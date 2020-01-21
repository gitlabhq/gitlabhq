# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class WaitingForResource < Status::Core
        def text
          s_('CiStatusText|waiting')
        end

        def label
          s_('CiStatusLabel|waiting for resource')
        end

        def icon
          'status_pending'
        end

        def favicon
          'favicon_pending'
        end

        def group
          'waiting-for-resource'
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Pending < Status::Core
        def text
          s_('CiStatusText|Pending')
        end

        def label
          s_('CiStatusLabel|pending')
        end

        def icon
          'status_pending'
        end

        def favicon
          'favicon_status_pending'
        end

        def details_path
          nil
        end
      end
    end
  end
end

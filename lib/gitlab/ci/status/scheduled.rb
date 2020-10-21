# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Scheduled < Status::Core
        def text
          s_('CiStatusText|delayed')
        end

        def label
          s_('CiStatusLabel|delayed')
        end

        def icon
          'status_scheduled'
        end

        def favicon
          'favicon_status_scheduled'
        end

        def details_path
          nil
        end
      end
    end
  end
end

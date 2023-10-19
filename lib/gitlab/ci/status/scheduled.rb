# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Scheduled < Status::Core
        def text
          s_('CiStatusText|Scheduled')
        end

        def label
          s_('CiStatusLabel|scheduled')
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

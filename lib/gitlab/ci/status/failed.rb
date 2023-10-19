# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Failed < Status::Core
        def text
          s_('CiStatusText|Failed')
        end

        def label
          s_('CiStatusLabel|failed')
        end

        def icon
          'status_failed'
        end

        def favicon
          'favicon_status_failed'
        end

        def details_path
          nil
        end
      end
    end
  end
end

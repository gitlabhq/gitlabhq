# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Manual < Status::Core
        def text
          s_('CiStatusText|Manual')
        end

        def label
          s_('CiStatusLabel|manual action')
        end

        def icon
          'status_manual'
        end

        def favicon
          'favicon_status_manual'
        end

        def details_path
          nil
        end
      end
    end
  end
end

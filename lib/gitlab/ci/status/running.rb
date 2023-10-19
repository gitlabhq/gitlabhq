# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Running < Status::Core
        def text
          s_('CiStatusText|Running')
        end

        def label
          s_('CiStatusLabel|running')
        end

        def icon
          'status_running'
        end

        def favicon
          'favicon_status_running'
        end

        def details_path
          nil
        end
      end
    end
  end
end

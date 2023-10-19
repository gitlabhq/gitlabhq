# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Success < Status::Core
        def text
          s_('CiStatusText|Passed')
        end

        def label
          s_('CiStatusLabel|passed')
        end

        def icon
          'status_success'
        end

        def favicon
          'favicon_status_success'
        end

        def details_path
          nil
        end
      end
    end
  end
end

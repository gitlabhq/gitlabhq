# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Canceled < Status::Core
        def text
          s_('CiStatusText|Canceled')
        end

        def label
          s_('CiStatusLabel|canceled')
        end

        def icon
          'status_canceled'
        end

        def favicon
          'favicon_status_canceled'
        end

        def details_path
          nil
        end
      end
    end
  end
end

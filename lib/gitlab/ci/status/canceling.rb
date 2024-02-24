# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Canceling < Status::Core
        def text
          s_('CiStatusText|Canceling')
        end

        def label
          s_('CiStatusLabel|canceling')
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

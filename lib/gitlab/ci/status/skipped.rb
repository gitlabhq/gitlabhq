# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Skipped < Status::Core
        def text
          s_('CiStatusText|Skipped')
        end

        def label
          s_('CiStatusLabel|skipped')
        end

        def icon
          'status_skipped'
        end

        def favicon
          'favicon_status_skipped'
        end

        def details_path
          nil
        end
      end
    end
  end
end

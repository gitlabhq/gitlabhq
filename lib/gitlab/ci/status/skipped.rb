module Gitlab
  module Ci
    module Status
      class Skipped < Status::Core
        def text
          _('skipped')
        end

        def label
          _('skipped')
        end

        def icon
          'icon_status_skipped'
        end

        def favicon
          'favicon_status_skipped'
        end
      end
    end
  end
end

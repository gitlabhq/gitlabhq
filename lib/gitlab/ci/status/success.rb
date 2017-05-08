module Gitlab
  module Ci
    module Status
      class Success < Status::Core
        def text
          _('passed')
        end

        def label
          _('passed')
        end

        def icon
          'icon_status_success'
        end

        def favicon
          'favicon_status_success'
        end
      end
    end
  end
end

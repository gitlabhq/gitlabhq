module Gitlab
  module Ci
    module Status
      class Created < Status::Core
        def text
          _('created')
        end

        def label
          _('created')
        end

        def icon
          'icon_status_created'
        end

        def favicon
          'favicon_status_created'
        end
      end
    end
  end
end

module Gitlab
  module Ci
    module Status
      class Created < Status::Core
        def text
          s_('CiStatus|created')
        end

        def label
          s_('CiStatus|created')
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

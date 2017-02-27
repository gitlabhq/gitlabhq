module Gitlab
  module Ci
    module Status
      class Created < Status::Core
        def text
          'created'
        end

        def label
          'created'
        end

        def icon
          'icon_status_created'
        end

        def favicon
          'build_status_created'
        end
      end
    end
  end
end

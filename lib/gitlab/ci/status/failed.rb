module Gitlab
  module Ci
    module Status
      class Failed < Status::Core
        def text
          'failed'
        end

        def label
          'failed'
        end

        def icon
          'icon_status_failed'
        end
      end
    end
  end
end

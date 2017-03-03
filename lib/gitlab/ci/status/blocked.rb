module Gitlab
  module Ci
    module Status
      class Blocked < Status::Core
        def text
          'blocked'
        end

        def label
          'blocked action'
        end

        def icon
          'icon_status_manual'
        end
      end
    end
  end
end

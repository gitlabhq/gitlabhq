module Gitlab
  module Ci
    module Status
      class Success < Status::Core
        def text
          'passed'
        end

        def label
          'passed'
        end

        def icon
          'icon_status_success'
        end
      end
    end
  end
end

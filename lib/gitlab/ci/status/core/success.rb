module Gitlab::Ci
  module Status
    module Core
      class Success < Core::Base
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

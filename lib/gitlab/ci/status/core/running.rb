module Gitlab::Ci
  module Status
    module Core
      class Running < Core::Base
        def text
          'running'
        end

        def label
          'running'
        end

        def icon
          'icon_status_running'
        end
      end
    end
  end
end

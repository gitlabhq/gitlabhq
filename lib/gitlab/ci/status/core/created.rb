module Gitlab::Ci
  module Status
    module Core
      class Created < Core::Base
        def text
          'created'
        end

        def label
          'created'
        end

        def icon
          'icon_status_created'
        end
      end
    end
  end
end

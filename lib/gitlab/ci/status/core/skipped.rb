module Gitlab::Ci
  module Status
    module Core
      class Skipped < Core::Base
        def label
          'skipped'
        end

        def icon
          'icon_status_skipped'
        end
      end
    end
  end
end

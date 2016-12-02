module Gitlab::Ci
  module Status
    module Core
      class Success
        def label
          'passed'
        end

        def icon
          'success'
        end
      end
    end
  end
end

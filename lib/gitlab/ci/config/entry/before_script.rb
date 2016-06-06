module Gitlab
  module Ci
    class Config
      module Entry
        class BeforeScript < BaseEntry
          def leaf?
            true
          end
        end
      end
    end
  end
end

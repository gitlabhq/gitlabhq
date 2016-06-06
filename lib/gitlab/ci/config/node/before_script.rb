module Gitlab
  module Ci
    class Config
      module Node
        class BeforeScript < Entry
          def leaf?
            true
          end
        end
      end
    end
  end
end

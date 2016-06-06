module Gitlab
  module Ci
    class Config
      module Node
        class Global < Entry
          def keys
            { before_script: BeforeScript }
          end
        end
      end
    end
  end
end

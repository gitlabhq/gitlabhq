module Gitlab
  module Ci
    class Config
      module Node
        class Entry
          def initialize(hash, config, parent = nil)
            @hash = hash
            @config = config
            @parent = parent
          end

          def allowed_keys
            []
          end
        end
      end
    end
  end
end

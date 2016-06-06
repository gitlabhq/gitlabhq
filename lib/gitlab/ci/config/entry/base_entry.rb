module Gitlab
  module Ci
    class Config
      module Entry
        class BaseEntry
          def initialize(hash, config, parent = nil)
            @hash = hash
            @config = config
            @parent = parent
          end
        end
      end
    end
  end
end

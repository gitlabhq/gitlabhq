module Gitlab
  module Ci
    class Config
      module Node
        class Global < Entry
          add_node :before_script, Script
        end
      end
    end
  end
end

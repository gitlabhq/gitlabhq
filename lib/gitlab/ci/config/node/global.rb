module Gitlab
  module Ci
    class Config
      module Node
        class Global < Entry
          include Configurable

          add_node :before_script, Script,
            description: 'Script that will be executed before each job.'
        end
      end
    end
  end
end

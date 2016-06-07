module Gitlab
  module Ci
    class Config
      module Node
        class Global < Entry
          add_node :before_script, BeforeScript

          def before_script
            @before_script.script
          end
        end
      end
    end
  end
end

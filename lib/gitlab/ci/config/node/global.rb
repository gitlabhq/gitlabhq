module Gitlab
  module Ci
    class Config
      module Node
        ##
        # This class represents a global entry - root node for entire
        # GitLab CI Configuration file.
        #
        class Global < Entry
          include Configurable

          allow_node :before_script, Script,
            description: 'Script that will be executed before each job.'

          allow_node :image, Image,
            description: 'Docker image that will be used to execute jobs.'
        end
      end
    end
  end
end

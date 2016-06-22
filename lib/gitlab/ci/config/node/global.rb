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

          node :before_script, Script,
            description: 'Script that will be executed before each job.'

          node :image, Image,
            description: 'Docker image that will be used to execute jobs.'

          node :services, Services,
            description: 'Docker images that will be linked to the container.'

          node :after_script, Script,
            description: 'Script that will be executed after each job.'

          node :variables, Variables,
            description: 'Environment variables that will be used.'
        end
      end
    end
  end
end

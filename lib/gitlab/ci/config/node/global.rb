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

          node :before_script, Node::Script,
            description: 'Script that will be executed before each job.'

          node :image, Node::Image,
            description: 'Docker image that will be used to execute jobs.'

          node :services, Node::Services,
            description: 'Docker images that will be linked to the container.'

          node :after_script, Node::Script,
            description: 'Script that will be executed after each job.'

          node :variables, Node::Variables,
            description: 'Environment variables that will be used.'

          node :stages, Node::Stages,
            description: 'Configuration of stages for this pipeline.'

          node :types, Node::Stages,
            description: 'Deprecated: stages for this pipeline.'

          node :cache, Node::Cache,
            description: 'Configure caching between build jobs.'

          helpers :before_script, :image, :services, :after_script,
                  :variables, :stages, :types, :cache

          def stages
            stages_defined? ? stages_value : types_value
          end
        end
      end
    end
  end
end

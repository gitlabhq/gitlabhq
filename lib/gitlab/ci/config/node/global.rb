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
                  :variables, :stages, :types, :cache, :jobs

          def initialize(*)
            super
            @global = self
          end

          private

          def compose!
            super

            compose_stages!
            compose_jobs!
          end

          def compose_stages!
            factory = Node::Factory.new(Node::Jobs)
            factory.value(@config.except(*nodes.keys))
            factory.with(key: :jobs, parent: self, global: self)
            factory.with(description: 'Jobs definition for this pipeline')

            @entries[:jobs] = factory.create!
          end

          def compose_jobs!
            if types_defined? && !stages_defined?
              @entries[:stages] = @entries[:types]
            end

            @entries.delete(:types)
          end
        end
      end
    end
  end
end

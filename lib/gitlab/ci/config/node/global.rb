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

          private

          def compose!
            super

            compose_jobs!
            compose_deprecated_entries!
          end

          def compose_jobs!
            factory = Node::Factory.new(Node::Jobs)
              .value(@config.except(*self.class.nodes.keys))
              .with(key: :jobs, parent: self,
                    description: 'Jobs definition for this pipeline')

            @entries[:jobs] = factory.create!
          end

          def compose_deprecated_entries!
            ##
            # Deprecated `:types` key workaround - if types are defined and
            # stages are not defined we use types definition as stages.
            #
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

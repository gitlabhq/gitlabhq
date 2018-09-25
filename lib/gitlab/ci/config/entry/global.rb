module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # This class represents a global entry - root Entry for entire
        # GitLab CI Configuration file.
        #
        class Global < Node
          include Configurable

          entry :before_script, Entry::Script,
            description: 'Script that will be executed before each job.'

          entry :image, Entry::Image,
            description: 'Docker image that will be used to execute jobs.'

          entry :services, Entry::Services,
            description: 'Docker images that will be linked to the container.'

          entry :after_script, Entry::Script,
            description: 'Script that will be executed after each job.'

          entry :variables, Entry::Variables,
            description: 'Environment variables that will be used.'

          entry :stages, Entry::Stages,
            description: 'Configuration of stages for this pipeline.'

          entry :types, Entry::Stages,
            description: 'Deprecated: stages for this pipeline.'

          entry :cache, Entry::Cache,
            description: 'Configure caching between build jobs.'

          helpers :before_script, :image, :services, :after_script,
                  :variables, :stages, :types, :cache, :jobs

          def compose!(_deps = nil)
            super(self) do
              compose_jobs!
              compose_deprecated_entries!
            end
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def compose_jobs!
            factory = Entry::Factory.new(Entry::Jobs)
              .value(@config.except(*self.class.nodes.keys))
              .with(key: :jobs, parent: self,
                    description: 'Jobs definition for this pipeline')

            @entries[:jobs] = factory.create!
          end
          # rubocop: enable CodeReuse/ActiveRecord

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

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Job < Node
          include Configurable
          include Attributable

          ALLOWED_KEYS = %i[tags script only except type image services allow_failure
                            type stage when artifacts cache dependencies before_script
                            after_script variables environment]

          attributes :tags, :allow_failure, :when, :dependencies

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :config, presence: true
            validates :name, presence: true
            validates :name, type: Symbol

            with_options allow_nil: true do
              validates :tags, array_of_strings: true
              validates :allow_failure, boolean: true
              validates :when,
                inclusion: { in: %w[on_success on_failure always manual],
                             message: 'should be on_success, on_failure, ' \
                                      'always or manual' }

              validates :dependencies, array_of_strings: true
            end
          end

          entry :before_script, Entry::Script,
            description: 'Global before script overridden in this job.'

          entry :script, Entry::Commands,
            description: 'Commands that will be executed in this job.'

          entry :stage, Entry::Stage,
            description: 'Pipeline stage this job will be executed into.'

          entry :type, Entry::Stage,
            description: 'Deprecated: stage this job will be executed into.'

          entry :after_script, Entry::Script,
            description: 'Commands that will be executed when finishing job.'

          entry :cache, Entry::Cache,
            description: 'Cache definition for this job.'

          entry :image, Entry::Image,
            description: 'Image that will be used to execute this job.'

          entry :services, Entry::Services,
            description: 'Services that will be used to execute this job.'

          entry :only, Entry::Trigger,
            description: 'Refs policy this job will be executed for.'

          entry :except, Entry::Trigger,
            description: 'Refs policy this job will be executed for.'

          entry :variables, Entry::Variables,
            description: 'Environment variables available for this job.'

          entry :artifacts, Entry::Artifacts,
            description: 'Artifacts configuration for this job.'

          entry :environment, Entry::Environment,
               description: 'Environment configuration for this job.'

          helpers :before_script, :script, :stage, :type, :after_script,
                  :cache, :image, :services, :only, :except, :variables,
                  :artifacts, :commands, :environment

          def compose!(deps = nil)
            super do
              if type_defined? && !stage_defined?
                @entries[:stage] = @entries[:type]
              end

              @entries.delete(:type)
            end

            inherit!(deps)
          end

          def name
            @metadata[:name]
          end

          def value
            @config.merge(to_hash.compact)
          end

          def commands
            (before_script_value.to_a + script_value.to_a).join("\n")
          end

          private

          def inherit!(deps)
            return unless deps

            self.class.nodes.each_key do |key|
              global_entry = deps[key]
              job_entry = @entries[key]

              if global_entry.specified? && !job_entry.specified?
                @entries[key] = global_entry
              end
            end
          end

          def to_hash
            { name: name,
              before_script: before_script,
              script: script,
              commands: commands,
              image: image,
              services: services,
              stage: stage,
              cache: cache,
              only: only,
              except: except,
              variables: variables_defined? ? variables : nil,
              environment: environment_defined? ? environment : nil,
              environment_name: environment_defined? ? environment[:name] : nil,
              artifacts: artifacts,
              after_script: after_script }
          end
        end
      end
    end
  end
end

module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Job < Entry
          include Configurable

          validations do
            validates :config, presence: true

            with_options on: :processed do
              validates :global, required: true
              validates :name, presence: true
              validates :name, type: Symbol
            end
          end

          node :before_script, Script,
            description: 'Global before script overridden in this job.'

          node :script, Commands,
            description: 'Commands that will be executed in this job.'

          node :stage, Stage,
            description: 'Pipeline stage this job will be executed into.'

          node :type, Stage,
            description: 'Deprecated: stage this job will be executed into.'

          node :after_script, Script,
            description: 'Commands that will be executed when finishing job.'

          helpers :before_script, :script, :stage, :type, :after_script

          def name
            @key
          end

          def value
            @config.merge(to_hash.compact)
          end

          private

          def to_hash
            { before_script: before_script_value,
              script: script_value,
              stage: stage_value,
              after_script: after_script_value }
          end

          def compose!
            super

            if type_defined? && !stage_defined?
              @entries[:stage] = @entries[:type]
            end

            @entries.delete(:type)
          end
        end
      end
    end
  end
end

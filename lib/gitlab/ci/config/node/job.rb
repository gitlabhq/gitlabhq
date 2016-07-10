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
          end

          node :before_script, Script,
            description: 'Global before script overridden in this job.'

          node :stage, Stage,
            description: 'Pipeline stage this job will be executed into.'

          node :type, Stage,
            description: 'Deprecated: stage this job will be executed into.'

          helpers :before_script, :stage, :type

          def value
            raise InvalidError unless valid?

            ##
            # TODO, refactoring step: do not expose internal configuration,
            # return only hash value without merging it to internal config.
            #
            @config.merge(to_hash.compact)
          end

          private

          def to_hash
            { before_script: before_script,
              stage: stage }
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

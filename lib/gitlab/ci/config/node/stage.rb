module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Entry that represents a stage for a job.
        #
        class Stage < Entry
          include Validatable

          validations do
            validates :config, key: true
            validates :global, required_attribute: true
            validate :known_stage, on: :processed

            def known_stage
              unless known?
                stages_list = global.stages.join(', ')
                errors.add(:config,
                           "should be one of defined stages (#{stages_list})")
              end
            end
          end

          def known?
            @global.stages.include?(@config)
          end

          def self.default
            :test
          end
        end
      end
    end
  end
end

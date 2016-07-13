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
            validates :config, type: String

            with_options on: :processed do
              validates :global, required: true

              validate do
                unless known?
                  errors.add(:config,
                             'should be one of defined stages ' \
                             "(#{global.stages.join(', ')})")
                end
              end
            end
          end

          def known?
            @global.stages.include?(@config)
          end

          def self.default
            'test'
          end
        end
      end
    end
  end
end

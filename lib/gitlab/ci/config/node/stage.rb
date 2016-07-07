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

            validate do |entry|
              unless entry.global
                raise Entry::InvalidError,
                  'This entry needs reference to global configuration'
              end
            end
          end

          def self.default
            :test
          end
        end
      end
    end
  end
end

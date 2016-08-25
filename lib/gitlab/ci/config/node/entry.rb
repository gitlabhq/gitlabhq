module Gitlab
  module Ci
    class Config
      module Node
        ##
        # Base abstract class for each configuration entry node.
        #
        class Entry
          class InvalidError < StandardError; end

          attr_reader :config, :metadata
          attr_accessor :key, :parent, :description

          def initialize(config, **metadata)
            @config = config
            @metadata = metadata
            @entries = {}

            @validator = self.class.validator.new(self)
            @validator.validate(:new)
          end

          def compose!(deps = nil)
            return unless valid?

            yield if block_given?
          end

          def leaf?
            @entries.none?
          end

          def descendants
            @entries.values
          end

          def ancestors
            @parent ? @parent.ancestors + [@parent] : []
          end

          def valid?
            errors.none?
          end

          def errors
            @validator.messages + descendants.flat_map(&:errors)
          end

          def value
            if leaf?
              @config
            else
              meaningful = @entries.select do |_key, value|
                value.specified? && value.relevant?
              end

              Hash[meaningful.map { |key, entry| [key, entry.value] }]
            end
          end

          def specified?
            true
          end

          def relevant?
            true
          end

          def self.default
          end

          def self.validator
            Validator
          end
        end
      end
    end
  end
end

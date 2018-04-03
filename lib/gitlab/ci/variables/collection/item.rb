module Gitlab
  module Ci
    module Variables
      class Collection
        class Item
          def initialize(**options)
            @variable = {
              key: options.fetch(:key),
              value: options.fetch(:value),
              public: options.fetch(:public, true),
              file: options.fetch(:files, false)
            }
          end

          def [](key)
            @variable.fetch(key)
          end

          def ==(other)
            to_runner_variable == self.class.fabricate(other).to_runner_variable
          end

          ##
          # If `file: true` has been provided we expose it, otherwise we
          # don't expose `file` attribute at all (stems from what the runner
          # expects).
          #
          def to_runner_variable
            @variable.reject do |hash_key, hash_value|
              hash_key == :file && hash_value == false
            end
          end

          def self.fabricate(resource)
            case resource
            when Hash
              self.new(resource)
            when ::HasVariable
              self.new(resource.to_runner_variable)
            when self
              resource.dup
            else
              raise ArgumentError, "Unknown `#{resource.class}` variable resource!"
            end
          end
        end
      end
    end
  end
end

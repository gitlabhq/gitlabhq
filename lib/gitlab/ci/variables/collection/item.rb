module Gitlab
  module Ci
    module Variables
      class Collection
        class Item
          def initialize(**options)
            @variable = {
              key: options.fetch(:key),
              value: options.fetch(:value),
              public: options.fetch(:public, false),
              file: options.fetch(:files, false)
            }
          end

          def ==(other)
            to_hash == self.class.fabricate(other).to_hash
          end

          ##
          # If `file: true` has been provided we expose it, otherwise we
          # don't expose `file` attribute at all (stems from what the runner
          # expects).
          #
          def to_hash
            @variable.reject do |hash_key, hash_value|
              hash_key == :file && hash_value == false
            end
          end

          def self.fabricate(resource)
            case resource
            when Hash
              self.new(resource)
            when ::Ci::Variable
              self.new(resource.to_hash)
            when self
              resource.dup
            else
              raise ArgumentError, 'Unknown CI/CD variable resource!'
            end
          end
        end
      end
    end
  end
end

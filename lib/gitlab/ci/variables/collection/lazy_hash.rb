# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Collection
        # LazyHash wraps a Variables::Collection and provides hash-like access
        # while preserving lazy evaluation of LazyItem values.
        class LazyHash
          def initialize(collection)
            @collection = collection
          end

          def [](key)
            @collection[key]
          end

          def fetch(key, default = nil)
            item = @collection[key]
            return default if item.nil?

            item.value
          end

          def with_indifferent_access
            self
          end

          def key?(key)
            raise NotImplementedError,
              "LazyHash does not support key? - use fetch(key, nil) to check if a variable is present"
          end
          alias_method :has_key?, :key?

          def to_hash
            raise NotImplementedError,
              "LazyHash#to_hash would evaluate all lazy variables. Use [] or fetch to access individual variables."
          end
          alias_method :to_h, :to_hash
        end
      end
    end
  end
end

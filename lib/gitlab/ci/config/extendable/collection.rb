module Gitlab
  module Ci
    class Config
      module Extendable
        class Collection
          include Enumerable

          ExtensionError = Class.new(StandardError)
          CircularDependencyError = Class.new(ExtensionError)

          def initialize(hash)
            @hash = hash
          end

          def each
            @hash.each_pair do |key, value|
              next unless value.key?(:extends)

              yield Extendable::Entry.new(key, @hash)
            end
          end

          def extend!
            each do |entry|
              raise ExtensionError unless entry.valid?

              entry.extend!
            end
          end
        end
      end
    end
  end
end

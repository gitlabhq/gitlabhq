module Gitlab
  module Ci
    class Config
      module Extendable
        class Collection
          include Enumerable

          ExtensionError = Class.new(StandardError)

          def initialize(hash, context = hash)
            @hash = hash
            @context = context
          end

          def each
            @hash.each_pair do |key, value|
              next unless value.key?(:extends)

              yield Extendable::Entry.new(key, value, @context)
            end
          end

          def extend!
            each do |entry|
              raise ExtensionError unless entry.valid?

              @hash[entry.key] = entry.extend!
            end
          end
        end
      end
    end
  end
end

module Gitlab
  module Ci
    class Config
      module Extendable
        class Collection
          include Enumerable

          ExtensionError = Class.new(StandardError)
          InvalidExtensionError = Class.new(ExtensionError)
          CircularDependencyError = Class.new(ExtensionError)

          def initialize(hash)
            @hash = hash.to_h.deep_dup

            each { |entry| entry.extend! if entry.extensible? }
          end

          def each
            @hash.each_key do |key|
              yield Extendable::Entry.new(key, @hash)
            end
          end

          def to_hash
            @hash.to_h
          end
        end
      end
    end
  end
end

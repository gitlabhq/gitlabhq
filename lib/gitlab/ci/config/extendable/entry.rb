module Gitlab
  module Ci
    class Config
      module Extendable
        class Entry
          attr_reader :key

          def initialize(key, hash, parent = nil)
            @key = key
            @hash = hash
            @parent = parent
          end

          def valid?
            true
          end

          def value
            @value ||= @hash.fetch(@key)
          end

          def base
            Extendable::Entry
              .new(extends, @hash, self)
              .extend!
          end

          def extensible?
            value.key?(:extends)
          end

          def extends
            value.fetch(:extends).to_sym
          end

          def extend!
            if extensible?
              @hash[key] = base.deep_merge(value)
            else
              value
            end
          end
        end
      end
    end
  end
end

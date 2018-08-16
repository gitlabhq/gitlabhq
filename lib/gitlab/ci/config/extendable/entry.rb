module Gitlab
  module Ci
    class Config
      module Extendable
        class Entry
          attr_reader :key

          def initialize(key, value, context, parent = nil)
            @key = key
            @value = value
            @context = context
            @parent = parent
          end

          def valid?
            true
          end

          # def circular_dependency?
          #   @extends.to_s == @key.to_s
          # end

          def base
            Extendable::Entry
              .new(extends, @context.fetch(extends), @context, self)
              .extend!
          end

          def extensible?
            @value.key?(:extends)
          end

          def extends
            @value.fetch(:extends).to_sym
          end

          def extend!
            if extensible?
              original = @value.dup
              parent = base.dup

              @value.clear.deep_merge!(parent).deep_merge!(original)
            else
              @value.to_h
            end
          end
        end
      end
    end
  end
end

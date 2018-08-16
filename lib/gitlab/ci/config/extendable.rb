module Gitlab
  module Ci
    class Config
      class Extendable
        include Enumerable

        ExtensionError = Class.new(StandardError)

        def initialize(hash)
          @hash = hash
        end

        def each
          @hash.each_pair do |key, value|
            next unless value.key?(:extends)

            yield key, value.fetch(:extends).to_sym, value
          end
        end

        def extend!
          @hash.tap do
            each do |key, extends, value|
              @hash[key] = @hash.fetch(extends).deep_merge(value)
            end
          end
        end
      end
    end
  end
end

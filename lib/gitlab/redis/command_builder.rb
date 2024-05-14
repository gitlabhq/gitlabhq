# frozen_string_literal: true

module Gitlab
  module Redis
    module CommandBuilder
      extend self

      RedisCommandNilArgumentError = Class.new(StandardError)

      # Ref: https://github.com/redis-rb/redis-client/blob/v0.19.1/lib/redis_client/command_builder.rb
      # we modify the command builder to convert nil to strings as this behaviour was present in
      # https://github.com/redis/redis-rb/blob/v4.8.0/lib/redis/connection/command_helper.rb#L20
      #
      # Note that we only adopt the Ruby3.x-compatible logic in .generate.
      # Symbol.method_defined?(:name) is true in Ruby 3
      def generate(args, kwargs = nil)
        command = args.flat_map do |element|
          case element
          when Hash
            element.flatten
          else
            element
          end
        end

        kwargs&.each do |key, value|
          if value
            if value == true
              command << key.name
            else
              command << key.name << value
            end
          end
        end

        command.map! do |element|
          case element
          when String
            element
          when Symbol
            element.name
          when Integer, Float
            element.to_s
          when NilClass
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
              RedisCommandNilArgumentError.new("nil arguments should be handled at the caller")
            )

            element.to_s
          else
            raise TypeError, "Unsupported command argument type: #{element.class}"
          end
        end

        raise ArgumentError, "can't issue an empty redis command" if command.empty?

        command
      end
    end
  end
end

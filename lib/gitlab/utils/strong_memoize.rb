# frozen_string_literal: true

module Gitlab
  module Utils
    module StrongMemoize
      # Instead of writing patterns like this:
      #
      #     def trigger_from_token
      #       return @trigger if defined?(@trigger)
      #
      #       @trigger = Ci::Trigger.find_by_token(params[:token].to_s)
      #     end
      #
      # We could write it like:
      #
      #     include Gitlab::Utils::StrongMemoize
      #
      #     def trigger_from_token
      #       strong_memoize(:trigger) do
      #         Ci::Trigger.find_by_token(params[:token].to_s)
      #       end
      #     end
      #
      def strong_memoize(name)
        key = ivar(name)

        if instance_variable_defined?(key)
          instance_variable_get(key)
        else
          instance_variable_set(key, yield)
        end
      end

      def strong_memoized?(name)
        instance_variable_defined?(ivar(name))
      end

      def clear_memoization(name)
        key = ivar(name)
        remove_instance_variable(key) if instance_variable_defined?(key)
      end

      private

      # Convert `"name"`/`:name` into `:@name`
      #
      # Depending on a type ensure that there's a single memory allocation
      def ivar(name)
        if name.is_a?(Symbol)
          name.to_s.prepend("@").to_sym
        elsif name.is_a?(String)
          :"@#{name}"
        else
          raise ArgumentError, "Invalid type of '#{name}'"
        end
      end
    end
  end
end

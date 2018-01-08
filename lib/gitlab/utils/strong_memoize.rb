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
        if instance_variable_defined?(ivar(name))
          instance_variable_get(ivar(name))
        else
          instance_variable_set(ivar(name), yield)
        end
      end

      def clear_memoization(name)
        remove_instance_variable(ivar(name)) if instance_variable_defined?(ivar(name))
      end

      private

      def ivar(name)
        "@#{name}"
      end
    end
  end
end

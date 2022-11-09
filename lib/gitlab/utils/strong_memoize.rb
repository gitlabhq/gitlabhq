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
      # Or like:
      #
      #     include Gitlab::Utils::StrongMemoize
      #
      #     def trigger_from_token
      #       Ci::Trigger.find_by_token(params[:token].to_s)
      #     end
      #     strong_memoize_attr :trigger_from_token
      #
      #     strong_memoize_attr :enabled?, :enabled
      #     def enabled?
      #       Feature.enabled?(:some_feature)
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

      def strong_memoize_with(name, *args)
        container = strong_memoize(name) { {} }

        if container.key?(args)
          container[args]
        else
          container[args] = yield
        end
      end

      def strong_memoized?(name)
        instance_variable_defined?(ivar(name))
      end

      def clear_memoization(name)
        key = ivar(name)
        remove_instance_variable(key) if instance_variable_defined?(key)
      end

      module StrongMemoizeClassMethods
        def strong_memoize_attr(method_name, member_name = nil)
          member_name ||= method_name

          if method_defined?(method_name) || private_method_defined?(method_name)
            StrongMemoize.send( # rubocop:disable GitlabSecurity/PublicSend
              :do_strong_memoize, self, method_name, member_name)
          else
            StrongMemoize.send( # rubocop:disable GitlabSecurity/PublicSend
              :queue_strong_memoize, self, method_name, member_name)
          end
        end

        def method_added(method_name)
          super

          if member_name = StrongMemoize
            .send(:strong_memoize_queue, self).delete(method_name) # rubocop:disable GitlabSecurity/PublicSend
            StrongMemoize.send( # rubocop:disable GitlabSecurity/PublicSend
              :do_strong_memoize, self, method_name, member_name)
          end
        end
      end

      def self.included(base)
        base.singleton_class.prepend(StrongMemoizeClassMethods)
      end

      private

      # Convert `"name"`/`:name` into `:@name`
      #
      # Depending on a type ensure that there's a single memory allocation
      def ivar(name)
        case name
        when Symbol
          name.to_s.prepend("@").to_sym
        when String
          :"@#{name}"
        else
          raise ArgumentError, "Invalid type of '#{name}'"
        end
      end

      class <<self
        private

        def strong_memoize_queue(klass)
          klass.instance_variable_get(:@strong_memoize_queue) || klass.instance_variable_set(:@strong_memoize_queue, {})
        end

        def queue_strong_memoize(klass, method_name, member_name)
          strong_memoize_queue(klass)[method_name] = member_name
        end

        def do_strong_memoize(klass, method_name, member_name)
          method = klass.instance_method(method_name)

          # Methods defined within a class method are already public by default, so we don't need to
          # explicitly make them public.
          scope = %i[private protected].find do |scope|
            klass.send("#{scope}_instance_methods") # rubocop:disable GitlabSecurity/PublicSend
              .include? method_name
          end

          klass.define_method(method_name) do |*args, &block|
            strong_memoize(member_name) do
              method.bind_call(self, *args, &block)
            end
          end

          klass.send(scope, method_name) if scope # rubocop:disable GitlabSecurity/PublicSend
        end
      end
    end
  end
end

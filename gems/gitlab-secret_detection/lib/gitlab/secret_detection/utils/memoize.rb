# frozen_string_literal: true

module Gitlab
  module SecretDetection
    module Utils
      # Pulled from GitLab.com source
      # Link: https://gitlab.com/gitlab-org/gitlab/-/blob/4713a798f997389f04e442db3d1d8349a39d5d46/gems/gitlab-utils/lib/gitlab/utils/strong_memoize.rb
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
        #     include Gitlab::SecretDetection::Utils::StrongMemoize
        #
        #     def trigger_from_token
        #       Ci::Trigger.find_by_token(params[:token].to_s)
        #     end
        #     strong_memoize_attr :trigger_from_token
        #
        #     def enabled?
        #       Feature.enabled?(:some_feature)
        #     end
        #     strong_memoize_attr :enabled?
        #
        def strong_memoize(name)
          key = ivar(name)

          if instance_variable_defined?(key)
            instance_variable_get(key)
          else
            instance_variable_set(key, yield)
          end
        end

        # Works the same way as "strong_memoize" but takes
        # a second argument - expire_in. This allows invalidate
        # the data after specified number of seconds
        def strong_memoize_with_expiration(name, expire_in)
          key = ivar(name)
          expiration_key = "#{key}_expired_at"

          if instance_variable_defined?(expiration_key)
            expire_at = instance_variable_get(expiration_key)
            clear_memoization(name) if expire_at.past?
          end

          if instance_variable_defined?(key)
            instance_variable_get(key)
          else
            value = instance_variable_set(key, yield)
            instance_variable_set(expiration_key, Time.current + expire_in)
            value
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
          key = ivar(StrongMemoize.normalize_key(name))
          instance_variable_defined?(key)
        end

        def clear_memoization(name)
          key = ivar(StrongMemoize.normalize_key(name))
          remove_instance_variable(key) if instance_variable_defined?(key)
        end

        module StrongMemoizeClassMethods
          def strong_memoize_attr(method_name)
            member_name = StrongMemoize.normalize_key(method_name)

            StrongMemoize.send(:do_strong_memoize, self, method_name, member_name) # rubocop:disable GitlabSecurity/PublicSend -- Same reason as Gitlab;:Utils::StrongMemoize
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

        class << self
          def normalize_key(key)
            return key unless key.end_with?('!', '?')

            # Replace invalid chars like `!` and `?` with allowed Unicode codeparts.
            key.to_s.tr('!?', "\uFF01\uFF1F")
          end

          private

          def do_strong_memoize(klass, method_name, member_name)
            method = klass.instance_method(method_name)

            unless method.arity.zero?
              raise <<~ERROR
                Using `strong_memoize_attr` on methods with parameters is not supported.

                Use `strong_memoize_with` instead.
                See https://docs.gitlab.com/ee/development/utilities.html#strongmemoize
              ERROR
            end

            # Methods defined within a class method are already public by default, so we don't need to
            # explicitly make them public.
            scope = %i[private protected].find do |scope|
              klass.send(:"#{scope}_instance_methods") # rubocop:disable GitlabSecurity/PublicSend -- For the same reason as Gitlab::Utils::StrongMemoise
                   .include? method_name
            end

            klass.define_method(method_name) do |&block|
              strong_memoize(member_name) do
                method.bind_call(self, &block)
              end
            end

            klass.send(scope, method_name) if scope # rubocop:disable GitlabSecurity/PublicSend -- For the same reason as Gitlab::Utils::StrongMemoise
          end
        end
      end
    end
  end
end

module Gitlab
  module Utils
    module Override
      # Instead of writing patterns like this:
      #
      #     def f
      #       raise NotImplementedError unless defined?(super)
      #
      #       true
      #     end
      #
      # We could write it like:
      #
      #     include ::Gitlab::Utils::Override
      #
      #     override :f
      #     def f
      #       true
      #     end
      #
      # This would make sure we're overriding something. See:
      # https://gitlab.com/gitlab-org/gitlab-ee/issues/1819
      def override(method_name)
        return unless ENV['STATIC_VERIFICATION']
        return if instance_methods.include?(method_name)

        raise NotImplementedError.new("Method #{method_name} doesn't exist")
      end
    end
  end
end

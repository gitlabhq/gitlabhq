module QA
  module Runtime
    module Namespace
      extend self

      def time
        @time ||= Time.now
      end

      def name
        "qa-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}"
      end

      def path
        "#{sandbox_name}/#{name}"
      end

      def sandbox_name
        Runtime::Env.sandbox_name || 'gitlab-qa-sandbox-group'
      end
    end
  end
end

module QA
  module Runtime
    module Namespace
      extend self

      def time
        @time ||= Time.now
      end

      def name
        'qa-test-' + time.strftime('%d-%m-%Y-%H-%M-%S')
      end

      def path
        "#{sandbox_name}/#{name}"
      end

      def sandbox_name
        Runtime::Env.sandbox_name || 'gitlab-qa-sandbox'
      end
    end
  end
end

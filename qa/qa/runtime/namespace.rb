# frozen_string_literal: true

module QA
  module Runtime
    module Namespace
      extend self

      def time
        @time ||= Time.now
      end

      def name
        # If any changes are made to the name tag, following script has to be considered:
        # https://ops.gitlab.net/gitlab-com/gl-infra/traffic-generator/blob/master/bin/janitor.bash
        @name ||= Runtime::Env.namespace_name || "qa-test-#{time.strftime('%Y-%m-%d-%H-%M-%S')}-#{SecureRandom.hex(8)}"
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

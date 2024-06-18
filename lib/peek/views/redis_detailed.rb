# frozen_string_literal: true

module Peek
  module Views
    class RedisDetailed < DetailedView
      REDACTED_MARKER = "<redacted>"

      def key
        'redis'
      end

      def detail_store
        ::Gitlab::Instrumentation::Redis.detail_store
      end

      private

      def format_call_details(call)
        call[:commands] = call[:commands].map { |command| format_command(command) }
        cmd = call[:commands].map { |command| command.join(' ') }.join(', ')

        super.merge(cmd: cmd,
          instance: call[:storage])
      end

      def format_command(cmd)
        # Perform a deep clone of commands if any auth commands are present as ["AUTH", password]
        # is a reference to `RedisClient::Config.connection_prelude`. `format_command` will update
        # the password to <redacted> and lead to NOAUTH errors.
        #
        # See issue: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2826
        if cmd.length >= 2 && cmd.first =~ /^auth$/i
          cmd = cmd.deep_dup
          cmd[-1] = REDACTED_MARKER
        # Scrub out the value of the SET calls to avoid binary
        # data or large data from spilling into the view
        elsif cmd.length >= 3 && cmd.first =~ /set/i
          cmd = cmd.deep_dup
          cmd[2..-1] = REDACTED_MARKER
        end

        cmd
      end
    end
  end
end

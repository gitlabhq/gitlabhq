# frozen_string_literal: true

require 'open3'

module Gitlab
  module Housekeeper
    class Shell
      Error = Class.new(StandardError)

      def self.execute(*cmd, env: {})
        env = ENV.to_h.merge(env)

        stdin, stdout, stderr, wait_thr = Open3.popen3(env, *cmd)

        stdin.close
        out = stdout.read
        stdout.close
        err = stderr.read
        stderr.close

        exit_status = wait_thr.value

        raise Error, "Failed with #{exit_status}\n#{out}\n#{err}\n" unless exit_status.success?

        out + err
      end

      # Run `rubocop --autocorrect --force-exclusion`.
      #
      # RuboCop is run without revealed TODOs.
      def self.rubocop_autocorrect(files)
        # Stop revealing RuboCop TODOs so RuboCop is only fixing material offenses.
        env = { 'REVEAL_RUBOCOP_TODO' => nil }
        cmd = ['rubocop', '--autocorrect', '--force-exclusion']

        ::Gitlab::Housekeeper::Shell.execute(*cmd, *files, env: env)
        true
      rescue ::Gitlab::Housekeeper::Shell::Error
        false
      end
    end
  end
end

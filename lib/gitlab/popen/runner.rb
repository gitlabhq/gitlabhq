# frozen_string_literal: true

module Gitlab
  module Popen
    class Runner
      attr_reader :results

      def initialize
        @results = []
      end

      def run(commands, &block)
        commands.each do |cmd|
          # yield doesn't support blocks, so we need to use a block variable
          block.call(cmd) do # rubocop:disable Performance/RedundantBlockCall
            cmd_result = Gitlab::Popen.popen_with_detail(cmd)

            results << cmd_result

            cmd_result
          end
        end
      end

      def all_success_and_clean?
        all_success? && all_stderr_empty?
      end

      def all_success?
        results.all? { |result| result.status.success? }
      end

      def all_stderr_empty?
        results.all? { |result| stderr_empty_ignoring_spring(result) }
      end

      def failed_results
        results.reject { |result| result.status.success? }
      end

      def warned_results
        results.select do |result|
          result.status.success? && !stderr_empty_ignoring_spring(result)
        end
      end

      private

      # NOTE: This is sometimes required instead of just calling `result.stderr.empty?`, if we
      # want to ignore the spring "Running via Spring preloader..." output to STDERR.
      # The `Spring.quiet=true` method which spring supports doesn't work, because it doesn't
      # work to make it quiet when using spring binstubs (the STDERR is printed by `bin/spring`
      # itself when first required, so there's no opportunity to set Spring.quiet=true).
      # This should probably be opened as a bug against Spring, with a pull request to support a
      # `SPRING_QUIET` env var as well.
      def stderr_empty_ignoring_spring(result)
        result.stderr.empty? || result.stderr =~ /\ARunning via Spring preloader in process [0-9]+\Z/
      end
    end
  end
end

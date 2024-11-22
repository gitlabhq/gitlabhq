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
          block.call(cmd) do
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
        results.all? { |result| result.stderr.empty? }
      end

      def failed_results
        results.reject { |result| result.status.success? }
      end

      def warned_results
        results.select do |result|
          result.status.success? && !result.stderr.empty?
        end
      end
    end
  end
end

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

      def all_good?
        all_status_zero? && all_stderr_empty?
      end

      def all_status_zero?
        results.all? { |result| result.status.zero? }
      end

      def all_stderr_empty?
        results.all? { |result| result.stderr.empty? }
      end

      def failed_results
        results.select { |result| result.status.nonzero? }
      end

      def warned_results
        results.select do |result|
          result.status.zero? && !result.stderr.empty?
        end
      end
    end
  end
end

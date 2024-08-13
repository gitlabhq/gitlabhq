# frozen_string_literal: true

module Gitlab
  module Verify
    class RakeTask
      def self.run!(verify_kls)
        verifier = verify_kls.new(
          batch_size: ENV.fetch('BATCH', 200).to_i,
          start: ENV['ID_FROM'],
          finish: ENV['ID_TO']
        )

        verbose = Gitlab::Utils.to_boolean(ENV['VERBOSE'])

        new(verifier, verbose).run!
      end

      attr_reader :verifier, :output

      def initialize(verifier, verbose)
        @verifier = verifier
        @verbose = verbose
      end

      def run!
        say "Checking integrity of #{verifier.name}"

        verifier.run_batches { |*args| run_batch(*args) }

        say 'Done!'
      end

      def verbose?
        !!@verbose
      end

      private

      def say(text)
        puts(text) # rubocop:disable Rails/Output
      end

      def run_batch(range, failures)
        status_color = failures.empty? ? :green : :red
        say Rainbow("- #{range}: Failures: #{failures.count}").color(status_color)

        return unless verbose?

        failures.each do |object, error|
          say Rainbow("  - #{verifier.describe(object)}: #{error}").color(:red)
        end
      end
    end
  end
end

# frozen_string_literal: true

require "slack-notifier"

module QA
  module Tools
    class LongRunningSpecReporter
      SLACK_CHANNEL = "#quality-reports"
      PROJECT = "gitlab-qa-resources"
      BUCKET = "knapsack-reports"
      RUNTIME_THRESHOLD = 300

      class << self
        delegate :execute, to: :new
      end

      # Find and report specs exceeding runtime threshold
      #
      # @return [void]
      def execute
        return puts("No long running specs detected, all good!") if long_running_specs.empty?

        specs = long_running_specs.map { |k, v| "#{k}: #{(v / 60).round(2)} minutes" }.join("\n")
        average = mean_runtime < 60 ? "#{mean_runtime.round(0)} seconds" : "#{(mean_runtime / 60).round(2)} minutes"
        msg = <<~MSG
          Following spec files are exceeding #{RUNTIME_THRESHOLD / 60} minute runtime threshold!
          Current average spec runtime: #{average}.
        MSG

        puts("#{msg}\n#{specs}")
        notifier.post(icon_emoji: ":time-out:", text: "#{msg}\n```#{specs}```")
      end

      private

      # Average runtime of spec files
      #
      # @return [Number]
      def mean_runtime
        @mean_runtime ||= knapsack_report.values
          .select { |v| v < RUNTIME_THRESHOLD }
          .then { |runtimes| runtimes.sum(0.0) / runtimes.length }
      end

      # Spec files exceeding runtime threshold
      #
      # @return [Hash]
      def long_running_specs
        @long_running_specs ||= knapsack_report.select { |_k, v| v > RUNTIME_THRESHOLD }
      end

      # Latest knapsack report
      #
      # @return [Hash]
      def knapsack_report
        @latest_report ||= JSON.parse(File.read(Support::KnapsackReport::FALLBACK_REPORT))
      end

      # Slack notifier
      #
      # @return [Slack::Notifier]
      def notifier
        @notifier ||= Slack::Notifier.new(
          slack_webhook_url,
          channel: SLACK_CHANNEL,
          username: "Spec Runtime Report"
        )
      end

      # Slack webhook url
      #
      # @return [String]
      def slack_webhook_url
        @slack_webhook_url ||= ENV["SLACK_WEBHOOK"] || raise("Missing SLACK_WEBHOOK env variable")
      end
    end
  end
end

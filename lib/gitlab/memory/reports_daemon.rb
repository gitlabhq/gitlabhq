# frozen_string_literal: true

module Gitlab
  module Memory
    class ReportsDaemon < Daemon
      DEFAULT_SLEEP_S = 7200 # 2 hours
      DEFAULT_SLEEP_MAX_DELTA_S = 600 # 0..10 minutes
      DEFAULT_SLEEP_BETWEEN_REPORTS_S = 120 # 2 minutes

      def initialize(reporter: nil, reports: nil, **options)
        super

        @alive = true

        @sleep_s =
          ENV['GITLAB_DIAGNOSTIC_REPORTS_SLEEP_S']&.to_i || DEFAULT_SLEEP_S
        @sleep_max_delta_s =
          ENV['GITLAB_DIAGNOSTIC_REPORTS_SLEEP_MAX_DELTA_S']&.to_i || DEFAULT_SLEEP_MAX_DELTA_S
        @sleep_between_reports_s =
          ENV['GITLAB_DIAGNOSTIC_REPORTS_SLEEP_BETWEEN_REPORTS_S']&.to_i || DEFAULT_SLEEP_BETWEEN_REPORTS_S

        @reporter = reporter || Reporter.new
        @reports = reports || [
          Gitlab::Memory::Reports::JemallocStats.new
        ]
      end

      attr_reader :sleep_s, :sleep_max_delta_s, :sleep_between_reports_s

      def run_thread
        while alive
          sleep interval_with_jitter

          reports.select(&:active?).each do |report|
            @reporter.run_report(report)

            sleep sleep_between_reports_s
          end
        end
      end

      private

      attr_reader :alive, :reports

      # Returns the sleep interval with a random adjustment.
      # The random adjustment is put in place to ensure continued availability.
      def interval_with_jitter
        sleep_s + rand(sleep_max_delta_s)
      end

      def stop_working
        @alive = false
      end
    end
  end
end

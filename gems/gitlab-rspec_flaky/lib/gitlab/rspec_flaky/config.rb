# frozen_string_literal: true

module Gitlab
  module RspecFlaky
    class Config
      def self.generate_report?
        !!(ENV['FLAKY_RSPEC_GENERATE_REPORT'] =~ /1|true/)
      end

      def self.suite_flaky_examples_report_path
        ENV['FLAKY_RSPEC_SUITE_REPORT_PATH'] || "rspec/flaky/suite-report.json"
      end

      def self.flaky_examples_report_path
        ENV['FLAKY_RSPEC_REPORT_PATH'] || "rspec/flaky/report.json"
      end

      def self.new_flaky_examples_report_path
        ENV['NEW_FLAKY_RSPEC_REPORT_PATH'] || "rspec/flaky/new-report.json"
      end
    end
  end
end

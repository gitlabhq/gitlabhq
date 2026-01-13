#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base_coverage_exporter'

# Exports backend coverage data to ClickHouse.
class BackendCoverageExporter < BaseCoverageExporter
  COVERAGE_REPORT = 'coverage-backend/coverage.lcov'
  TEST_MAP = 'crystalball/merged-mapping.json.gz'
  RSPEC_REPORTS_GLOB = 'rspec/rspec-*.json'
  E2E_REPORTS_GLOB = 'e2e-test-reports/rspec-*.json'

  private

  def summary_title
    "Backend Coverage Export Summary"
  end

  def coverage_report_path
    COVERAGE_REPORT
  end

  def test_map_path
    TEST_MAP
  end

  def test_reports_pattern
    "#{RSPEC_REPORTS_GLOB},#{E2E_REPORTS_GLOB}"
  end

  def artifact_status_lines
    [
      file_status(COVERAGE_REPORT, "Coverage report"),
      "  [✓] RSpec test reports: #{rspec_report_count} files",
      "  [✓] E2E test reports: #{e2e_report_count} files",
      file_status(TEST_MAP, "Test mapping")
    ]
  end

  def artifacts_available?
    rspec_report_count > 0 || e2e_report_count > 0
  end

  def rspec_report_count
    @rspec_report_count ||= Dir.glob(RSPEC_REPORTS_GLOB).count
  end

  def e2e_report_count
    @e2e_report_count ||= Dir.glob(E2E_REPORTS_GLOB).count
  end
end

if __FILE__ == $PROGRAM_NAME
  exporter = BackendCoverageExporter.new
  exporter.run
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base_coverage_exporter'

# Exports frontend coverage data to ClickHouse.
class FrontendCoverageExporter < BaseCoverageExporter
  COVERAGE_REPORT = 'coverage-frontend/lcov.info'
  TEST_MAP = 'jest-test-mapping/merged-source-to-test.json'
  JEST_REPORTS_GLOB = 'jest-reports/**/*.json'
  E2E_REPORTS_GLOB = 'e2e-test-reports/rspec-*.json'

  private

  def summary_title
    "Frontend Coverage Export Summary"
  end

  def coverage_report_path
    COVERAGE_REPORT
  end

  def test_map_path
    TEST_MAP
  end

  def test_reports_pattern
    "#{JEST_REPORTS_GLOB},#{E2E_REPORTS_GLOB}"
  end

  def artifact_status_lines
    [
      file_status(COVERAGE_REPORT, "Coverage report"),
      "  [✓] Jest test reports: #{jest_report_count} files",
      "  [✓] E2E test reports: #{e2e_report_count} files",
      file_status(TEST_MAP, "Test mapping")
    ]
  end

  def artifacts_available?
    jest_report_count > 0 || e2e_report_count > 0
  end

  def jest_report_count
    @jest_report_count ||= Dir.glob(JEST_REPORTS_GLOB).count
  end

  def e2e_report_count
    @e2e_report_count ||= Dir.glob(E2E_REPORTS_GLOB).count
  end
end

if __FILE__ == $PROGRAM_NAME
  exporter = FrontendCoverageExporter.new
  exporter.run
end

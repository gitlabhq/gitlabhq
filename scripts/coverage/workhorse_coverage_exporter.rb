#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'base_coverage_exporter'

# Exports workhorse (Go) coverage data to ClickHouse.
class WorkhorseCoverageExporter < BaseCoverageExporter
  COVERAGE_REPORT = 'workhorse/coverage.lcov'
  TEST_REPORT = 'workhorse-test-reports/workhorse-tests.json'
  TEST_MAP = 'workhorse-test-mapping/workhorse-source-to-test.json'

  private

  def summary_title
    "Workhorse Coverage Export Summary"
  end

  def coverage_report_path
    COVERAGE_REPORT
  end

  def test_map_path
    TEST_MAP
  end

  def test_reports_pattern
    TEST_REPORT
  end

  def artifact_status_lines
    [
      file_status(COVERAGE_REPORT, "Coverage report"),
      file_status(TEST_REPORT, "Test report"),
      file_status(TEST_MAP, "Test mapping")
    ]
  end

  def artifacts_available?
    File.exist?(TEST_REPORT)
  end

  def missing_artifacts_message
    "test report not found"
  end
end

if __FILE__ == $PROGRAM_NAME
  exporter = WorkhorseCoverageExporter.new
  exporter.run
end

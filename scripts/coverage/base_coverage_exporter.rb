#!/usr/bin/env ruby
# frozen_string_literal: true

# Base class for coverage exporters.
#
# Provides common functionality for checking artifacts and exporting
# coverage data to ClickHouse. Subclasses must implement the abstract
# methods to define their specific artifacts and configuration.
class BaseCoverageExporter
  RESPONSIBILITY_PATTERNS = '.gitlab/coverage/responsibility_patterns.yml'

  def initialize(env: ENV)
    @env = env
  end

  def run
    print_summary
    return true unless can_export?

    export_to_clickhouse
  end

  private

  attr_reader :env

  # Abstract methods - subclasses must implement these
  def summary_title
    raise NotImplementedError
  end

  def coverage_report_path
    raise NotImplementedError
  end

  def test_map_path
    raise NotImplementedError
  end

  def test_reports_pattern
    raise NotImplementedError
  end

  def artifact_status_lines
    raise NotImplementedError
  end

  def artifacts_available?
    raise NotImplementedError
  end

  # Common implementation
  def print_summary
    puts "\n=== #{summary_title} ===\n\n"
    puts "Checking artifacts..."
    artifact_status_lines.each { |line| puts line }
    puts ""
  end

  def file_status(path, label)
    if File.exist?(path)
      "  [✓] #{label}: #{path}"
    else
      "  [✗] #{label}: NOT FOUND"
    end
  end

  def can_export?
    unless File.exist?(coverage_report_path)
      puts "Skipping export: coverage report not found"
      return false
    end

    unless artifacts_available?
      puts "Skipping export: #{missing_artifacts_message}"
      return false
    end

    unless File.exist?(test_map_path)
      puts "Skipping export: test mapping not found"
      return false
    end

    true
  end

  def missing_artifacts_message
    "no test reports found"
  end

  def export_to_clickhouse
    puts "Exporting to ClickHouse..."

    success = system(
      'bundle', 'exec', 'test-coverage',
      '--test-reports', test_reports_pattern,
      '--coverage-report', coverage_report_path,
      '--test-map', test_map_path,
      '--clickhouse-url', env.fetch('CLICKHOUSE_URL', ''),
      '--clickhouse-database', env.fetch('CLICKHOUSE_DATABASE', ''),
      '--clickhouse-shared-database', env.fetch('CLICKHOUSE_SHARED_DB', ''),
      '--clickhouse-username', env.fetch('CLICKHOUSE_USERNAME', ''),
      '--responsibility-patterns', RESPONSIBILITY_PATTERNS
    )

    puts "\n=== Export Complete ==="

    success
  end
end

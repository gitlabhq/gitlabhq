#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'

require_relative 'path_normalizer'

# Merges backend coverage from RSpec (LCOV) and E2E Coverband (JSON) into a single LCOV file.
class BackendCoverageMerger
  RSPEC_LCOV_PATH = 'coverage/lcov/gitlab.lcov'
  E2E_COVERBAND_GLOB = 'coverage-e2e-backend/coverband-coverage-*.json'
  OUTPUT_DIR = 'coverage-backend'
  OUTPUT_FILE = "#{OUTPUT_DIR}/coverage.lcov".freeze

  def initialize(rspec_lcov: RSPEC_LCOV_PATH, e2e_coverband_glob: E2E_COVERBAND_GLOB)
    @rspec_lcov_path = rspec_lcov
    @e2e_coverband_files = Dir.glob(e2e_coverband_glob)
  end

  def merge
    puts "====== Merging Backend Coverage ======"

    coverage = {}

    load_rspec_coverage(coverage)
    load_e2e_coverband_coverage(coverage)

    if coverage.empty?
      warn "ERROR: No coverage data found"
      exit 1
    end

    write_lcov(coverage)

    puts ""
    puts "====== Backend Coverage Merge Complete ======"
    puts "Output: #{OUTPUT_FILE}"
  end

  private

  def load_rspec_coverage(coverage)
    if File.exist?(@rspec_lcov_path)
      puts "Loading RSpec coverage from #{@rspec_lcov_path}..."
      parse_lcov(@rspec_lcov_path, coverage)
      puts "  Loaded coverage for #{coverage.size} files"
    else
      warn "WARNING: No RSpec coverage found at #{@rspec_lcov_path}"
    end
  end

  def load_e2e_coverband_coverage(coverage)
    if @e2e_coverband_files.empty?
      puts "No E2E Coverband coverage files found. Using RSpec coverage only."
      return
    end

    puts "Loading E2E Coverband coverage (#{@e2e_coverband_files.length} files)..."
    files_before = coverage.size

    @e2e_coverband_files.each do |file|
      parse_coverband_json(file, coverage)
    end

    puts "  Merged coverage from E2E tests (#{coverage.size - files_before} new files)"
  end

  def parse_lcov(path, coverage)
    current_file = nil

    File.foreach(path) do |line|
      line = line.strip

      case line
      when /^SF:(.+)$/
        current_file = Regexp.last_match(1)
        coverage[current_file] ||= { lines: {}, branches: [], branch_stats: { found: 0, hit: 0 } }
      when /^DA:(\d+),(\d+)/
        next unless current_file

        line_num = Regexp.last_match(1).to_i
        hits = Regexp.last_match(2).to_i
        coverage[current_file][:lines][line_num] = (coverage[current_file][:lines][line_num] || 0) + hits
      when /^BRDA:(\d+),(\d+),(\d+),(-|\d+)$/
        next unless current_file

        # BRDA:line,block,branch,taken
        coverage[current_file][:branches] << line
      when /^BRF:(\d+)$/
        next unless current_file

        coverage[current_file][:branch_stats][:found] = Regexp.last_match(1).to_i
      when /^BRH:(\d+)$/
        next unless current_file

        coverage[current_file][:branch_stats][:hit] = Regexp.last_match(1).to_i
      when 'end_of_record'
        current_file = nil
      end
    end
  end

  def parse_coverband_json(path, coverage)
    data = JSON.parse(File.read(path))

    data.each_value do |file_coverage|
      file_coverage.each do |filepath, line_data|
        # Normalize paths to handle absolute paths and ./ prefix
        normalized_path = PathNormalizer.normalize(filepath)
        coverage[normalized_path] ||= { lines: {}, branches: [], branch_stats: { found: 0, hit: 0 } }
        merge_line_data(coverage[normalized_path][:lines], line_data)
      end
    end
  end

  def merge_line_data(target, line_data)
    line_hits_pairs = if line_data.is_a?(Array)
                        # Array format: index is 0-based, convert to 1-based line numbers
                        line_data.each_with_object([]).with_index do |(hits, pairs), index|
                          pairs << [index + 1, hits.to_i] unless hits.nil?
                        end
                      else
                        # Hash format: keys are line numbers (as strings), values are hit counts
                        line_data.map do |line_num, hits|
                          count = hits.is_a?(Array) ? hits.first.to_i : hits.to_i
                          [line_num.to_i, count]
                        end
                      end

    line_hits_pairs.each do |line, count|
      target[line] = (target[line] || 0) + count
    end
  end

  def write_lcov(coverage_data)
    FileUtils.mkdir_p(OUTPUT_DIR)

    temp_file = Tempfile.new(['coverage', '.lcov'], OUTPUT_DIR)

    begin
      temp_file.sync = true

      coverage_data.each do |filepath, file_data|
        temp_file.puts "TN:"
        temp_file.puts "SF:#{filepath}"

        # Write line coverage data
        file_data[:lines].keys.sort.each do |line_num|
          temp_file.puts "DA:#{line_num},#{file_data[:lines][line_num]}"
        end

        temp_file.puts "LF:#{file_data[:lines].size}"
        temp_file.puts "LH:#{file_data[:lines].values.count { |hits| hits > 0 }}"

        # Write branch coverage data if present
        if file_data[:branches].any?
          file_data[:branches].each do |branch_line|
            temp_file.puts branch_line
          end
          temp_file.puts "BRF:#{file_data[:branch_stats][:found]}"
          temp_file.puts "BRH:#{file_data[:branch_stats][:hit]}"
        end

        temp_file.puts "end_of_record"
      end

      temp_file.close
      FileUtils.mv(temp_file.path, OUTPUT_FILE)

      print_summary(coverage_data)
    rescue StandardError => e
      temp_file.close
      temp_file.unlink
      raise e
    end
  end

  def print_summary(coverage_data)
    total_lines = 0
    covered_lines = 0
    total_branches = 0
    covered_branches = 0

    coverage_data.each_value do |file_data|
      total_lines += file_data[:lines].size
      covered_lines += file_data[:lines].values.count { |hits| hits > 0 }
      total_branches += file_data[:branch_stats][:found]
      covered_branches += file_data[:branch_stats][:hit]
    end

    line_pct = total_lines > 0 ? (covered_lines.to_f / total_lines * 100).round(2) : 0
    branch_pct = total_branches > 0 ? (covered_branches.to_f / total_branches * 100).round(2) : 0

    puts ""
    puts "Coverage summary:"
    puts "  Files: #{coverage_data.size}"
    puts "  Lines: #{covered_lines}/#{total_lines} (#{line_pct}%)"
    puts "  Branches: #{covered_branches}/#{total_branches} (#{branch_pct}%)"
  end
end

if __FILE__ == $PROGRAM_NAME
  require 'tempfile'

  merger = BackendCoverageMerger.new
  merger.merge
end

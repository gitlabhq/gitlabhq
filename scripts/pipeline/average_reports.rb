#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'

class AverageReports
  attr_reader :initial_report_file, :initial_report_data, :report_file_to_data_map

  def initialize(initial_report_file:, new_report_files:)
    @initial_report_file = initial_report_file
    @initial_report_data = parse_json_from_report_file(initial_report_file)

    @report_file_to_data_map = new_report_files.each_with_object({}) do |report_file, map|
      next unless File.exist?(report_file)

      map[report_file] ||= parse_json_from_report_file(report_file)
    end
  end

  def execute
    puts "Updating #{initial_report_file} with #{report_file_to_data_map.size} new reports..."

    compound_reports = report_file_to_data_map.keys.each_with_object({}) do |report_file, result|
      report = report_file_to_data_map[report_file]

      report.each do |spec, duration|
        result[spec] ||= [*initial_report_data[spec]]
        result[spec] << duration
      end

      puts "Updated #{report.size} data points from #{report_file}"
    end

    averaged_reports = compound_reports.transform_values do |durations|
      durations.sum.to_f / durations.size
    end

    File.write(initial_report_file, JSON.pretty_generate(averaged_reports))
    puts "Saved #{initial_report_file}."

    averaged_reports
  end

  private

  def parse_json_from_report_file(report_file)
    JSON.parse(File.read(report_file))
  end
end

if $PROGRAM_NAME == __FILE__
  options = {}

  OptionParser.new do |opts|
    opts.on("-i", "--initial-report initial_report_file", String, 'Initial report file name') do |value|
      options[:initial_report_file] = value
    end

    opts.on("-n", "--new-reports new_report_files", Array, 'New report file names delimited by ","') do |values|
      options[:new_report_files] = values
    end
  end.parse!

  AverageReports.new(**options).execute
end

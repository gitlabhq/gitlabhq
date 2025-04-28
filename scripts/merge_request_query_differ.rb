#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'uri'
require 'net/http'
require 'zlib'
require 'rubygems/package'
require 'stringio'
require 'logger'
require_relative 'sql_fingerprint_extractor'

# MergeRequestQueryDiffer compares auto_explain logs from an MR against master
# to identify new query patterns introduced by the MR
class MergeRequestQueryDiffer
  PROJECT_ID = ENV['CI_PROJECT_ID'] || '278964'
  PACKAGE_NAME = 'auto-explain-logs'
  PACKAGE_FILE = 'query-fingerprints.tar.gz'
  NEW_QUERIES_PATH = 'new_sql_queries.md'
  CONSOLIDATED_FINGERPRINTS_URL = ENV['CONSOLIDATED_FINGERPRINTS_URL'] ||
    "https://gitlab.com/api/v4/projects/#{PROJECT_ID}/packages/generic/#{PACKAGE_NAME}/master/#{PACKAGE_FILE}"

  attr_reader :mr_auto_explain_path, :output_file, :logger, :sql_fingerprint_extractor, :report_generator

  def initialize(mr_auto_explain_path, logger = nil)
    @mr_auto_explain_path = mr_auto_explain_path
    output_dir = File.dirname(mr_auto_explain_path)
    @output_file = File.join(output_dir, NEW_QUERIES_PATH)
    @logger = logger || Logger.new($stdout)
    @sql_fingerprint_extractor = SQLFingerprintExtractor.new(@logger)
    @report_generator = ReportGenerator.new(@logger)
  end

  def run
    logger.info "MR Query Diff: Analyzing new queries in MR compared to master"

    # Step 1: Extract query fingerprints from MR
    mr_queries = sql_fingerprint_extractor.extract_queries_from_file(mr_auto_explain_path)
    if mr_queries.empty?
      logger.info "No queries found in MR file"
      write_report(output_file, "# SQL Query Analysis\n\nNo queries found in this MR.")
      return 0
    end

    mr_fingerprints = mr_queries.filter_map { |q| q['fingerprint'] }
    if mr_fingerprints.empty?
      logger.info "No fingerprints found in MR queries... exiting"
      return 0
    end

    logger.info "Found #{mr_fingerprints.size} total queries in MR"

    # Step 2: Get master fingerprints
    master_fingerprints = get_master_fingerprints
    if master_fingerprints.empty?
      logger.info "No master fingerprints found for comparison... exiting"
      return 0
    end

    # Step 3: Compare and filter
    mr_queries = filter_new_queries(mr_queries, master_fingerprints)

    # Step 4: Report generation
    logger.info "Final result: #{mr_queries.size} new queries compared to all master packages"
    report = report_generator.generate(mr_queries)
    write_report(output_file, report)
    mr_queries.size
  rescue StandardError => e
    logger.info "Error in main execution: #{e.message}"
    write_report(output_file, "# SQL Query Analysis\n\n️ Analysis failed: #{e.message}")
    0
  end

  def filter_new_queries(mr_queries, master_fingerprints)
    original_count = mr_queries.size
    logger.info "Filtering #{original_count} queries against master fingerprints..."

    # Only keep queries with fingerprints not in master set
    new_queries = mr_queries.select { |q| q['fingerprint'] && Set[q['fingerprint']].disjoint?(master_fingerprints) }

    filtered_count = original_count - new_queries.size
    logger.info "Filtered out #{filtered_count} existing queries, #{new_queries.size} new queries found"

    if new_queries.empty?
      logger.info "All queries in MR are already present in master packages"
      write_report(output_file, %(# SQL Query Analysis

        No new SQL queries detected in this MR.
        All queries in this MR are already present in master
      ))
    end

    new_queries
  end

  def get_master_fingerprints
    logger.info "Fetching master fingerprints from consolidated package..."
    fingerprints = Set.new

    begin
      content = download_consolidated_package
      if content.nil?
        logger.error "Failed to download consolidated package"
        return fingerprints
      end

      # Extract fingerprints from the package
      fingerprints = sql_fingerprint_extractor.extract_from_tar_gz(content)
      logger.info "Loaded #{fingerprints.size} master fingerprints from consolidated package"
    rescue StandardError => e
      logger.error "Error loading master fingerprints: #{e.message}"
    end

    fingerprints
  end

  def download_consolidated_package(max_size_mb = 100)
    logger.info "Downloading from: #{CONSOLIDATED_FINGERPRINTS_URL}"
    url = URI(CONSOLIDATED_FINGERPRINTS_URL)

    # Check file size first
    begin
      response = make_request(url, method: :head, parse_json: false)

      if response.is_a?(Net::HTTPResponse)
        content_length_mb = response['content-length'].to_i / (1024**2)
        if content_length_mb > max_size_mb
          logger.error "Package size (#{content_length_mb}MB) exceeds maximum allowed size (#{max_size_mb}MB)"
          return
        end
      end
    rescue StandardError => e
      logger.warn "Warning: Could not validate file size: #{e}"
    end

    make_request(url, method: :get, parse_json: false)
  end

  def write_report(output_file, content)
    File.write(output_file, content)
    logger.info "Report saved to #{output_file}"
  rescue StandardError => e
    logger.error "Could not write report to file: #{e.message}"
  end

  def make_request(url, method: :get, parse_json: true, attempt: 1, max_attempts: 10)
    if attempt >= max_attempts
      logger.info "Maximum retry attempts (#{max_attempts}) reached for rate limiting"
      return parse_json ? [] : nil
    end

    begin
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.read_timeout = 120

      request = build_request(method, url)
      if ENV['GITLAB_TOKEN']
        request['PRIVATE-TOKEN'] = ENV['GITLAB_TOKEN']
      elsif ENV['CI_JOB_TOKEN']
        request['JOB-TOKEN'] = ENV['CI_JOB_TOKEN']
      end

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        return response if method == :head

        if parse_json
          begin
            JSON.parse(response.body)
          rescue JSON::ParserError => e
            logger.error "Failed to parse JSON: #{e.message}"
            []
          end
        else
          response.body
        end

      when Net::HTTPTooManyRequests,
        Net::HTTPServerError,
        Net::HTTPInternalServerError,
        Net::HTTPServiceUnavailable,
        Net::HTTPGatewayTimeout,
        Net::HTTPBadGateway
        backoff = [1 * (2**attempt), 60].min
        logger.info "HTTP #{response.code} - Waiting and retrying after #{backoff} secs"
        sleep(backoff)
        make_request(
          url, method: method, parse_json: parse_json, attempt: attempt + 1, max_attempts: max_attempts
        )
      else
        logger.error "HTTP request failed: #{response.code} - #{response.message}"
        parse_json ? [] : nil
      end

    rescue StandardError => e
      logger.error "Error making request: #{e}"
      parse_json ? [] : nil
    end
  end

  private

  def build_request(method, url)
    case method
    when :get
      Net::HTTP::Get.new(url)
    when :head
      Net::HTTP::Head.new(url)
    else
      raise ArgumentError, "Unsupported HTTP method: #{method}"
    end
  end

  # ReportGenerator handles creation of readable reports from query data
  class ReportGenerator
    attr_reader :logger

    def initialize(logger)
      @logger = logger || Logger.new($stdout)
    end

    def generate(mr_queries)
      report = "# SQL Query Analysis\n\n"

      if mr_queries.empty?
        report += "No new SQL queries detected in this MR."
        return report
      end

      report += "## Identified potential #{mr_queries.size} new SQL queries:\n\n"

      mr_queries.each_with_index do |query, idx|
        next unless query['normalized']

        report += <<~DETAILS
          <details>
          <summary><b>Query #{idx + 1}</b>: #{format_query_summary(query)}</summary>

          ```sql
          #{query['normalized']}
          ```

          **Fingerprint:** `#{query['fingerprint']}`

          #{query['plan'] ? format_plan(query['plan']) : ''}
          </details>
        DETAILS
      end

      report
    end

    def format_query_summary(query)
      text = query['normalized'] || ""

      cleaned = text.gsub(/\s+/, ' ').strip
      cleaned.size > 80 ? "#{cleaned[0..77]}..." : cleaned
    end

    def format_plan(plan)
      return "" unless plan

      <<~PLAN
          **Execution Plan:**
          ```json
          #{
          if plan.is_a?(Hash)
            JSON.pretty_generate(plan)
          else
            plan.respond_to?(:to_s) ? plan.to_s : plan.inspect
          end
        }
          ```

      PLAN
    end
  end
  private_constant :ReportGenerator
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts "Usage: #{$PROGRAM_NAME} <path/to/mr_auto_explain.ndjson[.gz]>"
    exit 1
  end

  mr_auto_explain_path = ARGV[0]
  unless File.exist?(mr_auto_explain_path)
    puts "Error: File not found - #{mr_auto_explain_path}"
    exit 1
  end

  diff = MergeRequestQueryDiffer.new(mr_auto_explain_path)
  diff.run
end

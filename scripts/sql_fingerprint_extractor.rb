#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'zlib'
require 'logger'
require 'stringio'
require 'rubygems/package'

# SQLFingerprintExtractor extracts and processes SQL query fingerprints
# from various file formats including NDJSON, gzipped NDJSON, and tar.gz archives
class SQLFingerprintExtractor
  attr_reader :logger

  def initialize(logger = nil)
    @logger = logger || Logger.new($stdout)
  end

  # Extract fingerprints from a local file (compressed or uncompressed)
  # Returns an array of query objects with fingerprints
  def extract_queries_from_file(file_path)
    logger.info "Extracting queries from file: #{file_path}" if logger
    queries = []

    begin
      if file_path.end_with?('.gz')
        Zlib::GzipReader.open(file_path) do |gz|
          gz.each_line do |line|
            process_json_line(line, queries)
          end
        end
      else
        File.foreach(file_path) do |line|
          process_json_line(line, queries)
        end
      end
    rescue StandardError => e
      logger.warn "Warning: Error reading file: #{e.message}" if logger
      return [] # Return empty array on error
    end

    logger.info "Extracted #{queries.size} queries from file: #{file_path}" if logger
    queries
  end

  # Extract just the fingerprint strings from a file
  # Returns a Set of fingerprint strings
  def extract_fingerprints_from_file(file_path)
    queries = extract_queries_from_file(file_path)
    Set.new(queries.filter_map { |q| q['fingerprint'] })
  end

  # Extract fingerprints from a tar.gz content
  # Returns a Set of fingerprint strings
  def extract_from_tar_gz(content, max_size_mb = 250)
    fingerprints = Set.new
    max_size = max_size_mb * (1024**2) # guardrail to prevent issues if unexpectedly large

    begin
      io = StringIO.new(content)
      gz = Zlib::GzipReader.new(io)
      tar = Gem::Package::TarReader.new(gz)

      tar&.each do |entry|
        # Now looking for raw fingerprint files (any text file)
        next unless entry.file? && !entry.directory?

        # Check file size before reading
        if entry.header.size > max_size
          logger.error(
            "File too large: #{entry.header.size / (1024**2)}MB exceeds limit #{max_size_mb}MB"
          )
          return fingerprints
        end

        entry_content = entry.read
        entry_content.each_line do |line|
          fingerprint = line.strip
          fingerprints.add(fingerprint) unless fingerprint.empty?
        end
      end
    rescue StandardError => e
      logger.error "Error processing tar.gz: #{e.message}"
      return Set.new
    end

    fingerprints
  end

  # Write a set of fingerprints to file
  def write_fingerprints_to_file(fingerprints, output_file)
    File.open(output_file, 'w') do |f|
      fingerprints.each { |fp| f.puts(fp) }
    end
    logger.info "Wrote #{fingerprints.size} fingerprints to #{output_file}" if logger
  end

  private

  def process_json_line(line, queries)
    data = JSON.parse(line)
    queries << data if data['fingerprint']
  rescue JSON::ParserError
    # Skip invalid JSON
  end
end

# Command-line script functionality
if __FILE__ == $PROGRAM_NAME
  if ARGV.size < 2
    puts "Usage: #{$PROGRAM_NAME} <input_file> <output_file>"
    exit 1
  end

  input_file = ARGV[0]
  output_file = ARGV[1]
  logger = Logger.new($stdout)

  unless File.exist?(input_file)
    logger.error "Input file not found - #{input_file}"
    exit 1
  end

  begin
    extractor = SQLFingerprintExtractor.new
    fingerprints = extractor.extract_fingerprints_from_file(input_file)
    extractor.write_fingerprints_to_file(fingerprints, output_file)
    logger.info "Successfully extracted #{fingerprints.size} fingerprints to #{output_file}"
  rescue StandardError => e
    logger.error e.message.to_s
    exit 1
  end
end

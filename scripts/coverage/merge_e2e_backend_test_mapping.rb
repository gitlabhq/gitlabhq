#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'zlib'
require 'stringio'
require 'fileutils'

require_relative '../../tooling/lib/tooling/test_map_packer'

# Merges E2E test mappings with Crystalball RSpec mappings.
#
# E2E mappings (test -> sources) are inverted to source -> tests format,
# then merged with Crystalball mappings to produce a combined mapping file.
class BackendTestMappingMerger
  CRYSTALBALL_MAPPING_PATH = 'crystalball/packed-mapping.json.gz'
  MERGED_MAPPING_PATH = 'crystalball/merged-mapping.json.gz'
  E2E_MAPPING_ARTIFACT_GLOB = 'e2e-test-mapping/test-code-paths-mapping-*.json'

  def run
    puts "=== E2E Test Mapping Merger ==="

    e2e_mapping = load_e2e_mapping
    if e2e_mapping.nil? || e2e_mapping.empty?
      warn "ERROR: No E2E mappings found"
      return false
    end

    inverted_e2e_mapping = invert_mapping(e2e_mapping)
    puts "Inverted E2E mapping: #{inverted_e2e_mapping.size} source files"

    crystalball_mapping = load_crystalball_mapping
    if crystalball_mapping.nil?
      warn "ERROR: Crystalball mapping not found at #{CRYSTALBALL_MAPPING_PATH}"
      return false
    end

    puts "Loaded Crystalball mapping: #{crystalball_mapping.size} source files"

    merged_mapping = merge_mappings(crystalball_mapping, inverted_e2e_mapping)
    puts "Merged mapping: #{merged_mapping.size} source files"

    save_merged_mapping(merged_mapping)
    puts "=== Merge complete ==="
    true
  end

  private

  # Loads and merges all E2E mapping files from artifacts.
  def load_e2e_mapping
    local_files = Dir.glob(E2E_MAPPING_ARTIFACT_GLOB)
    return if local_files.empty?

    puts "Found #{local_files.size} E2E mapping files"

    local_files.each_with_object({}) do |file, merged|
      data = JSON.parse(File.read(file))
      data.each do |test, sources|
        merged[test] ||= []
        merged[test] = (merged[test] + Array(sources)).uniq
      end
    rescue JSON::ParserError => e
      warn "WARNING: Failed to parse #{file}: #{e.message}"
    end
  end

  # Inverts mapping from test -> sources to source -> tests.
  def invert_mapping(test_to_sources)
    test_to_sources.each_with_object({}) do |(test_file, source_files), source_to_tests|
      Array(source_files).each do |source_file|
        source_to_tests[source_file] ||= []
        source_to_tests[source_file] << test_file unless source_to_tests[source_file].include?(test_file)
      end
    end
  end

  # Loads and unpacks Crystalball mapping from gzipped file.
  def load_crystalball_mapping
    return unless File.exist?(CRYSTALBALL_MAPPING_PATH)

    compressed = File.binread(CRYSTALBALL_MAPPING_PATH)
    json_content = Zlib::GzipReader.new(StringIO.new(compressed)).read
    packed_mapping = JSON.parse(json_content)

    test_map_packer.unpack(packed_mapping)
  end

  # Merges two source -> tests mappings, combining test lists for each source.
  def merge_mappings(crystalball_mapping, e2e_mapping)
    merged = crystalball_mapping.dup

    e2e_mapping.each do |source_file, tests|
      merged[source_file] ||= []
      merged[source_file] = (merged[source_file] + tests).uniq
    end

    merged
  end

  # Packs and saves the merged mapping to a gzipped file.
  def save_merged_mapping(mapping)
    FileUtils.mkdir_p(File.dirname(MERGED_MAPPING_PATH))

    packed_mapping = test_map_packer.pack(mapping)
    json_content = JSON.generate(packed_mapping)

    compressed = StringIO.new
    gz = Zlib::GzipWriter.new(compressed)
    gz.write(json_content)
    gz.close

    File.binwrite(MERGED_MAPPING_PATH, compressed.string)
    puts "Saved merged mapping to #{MERGED_MAPPING_PATH}"
  end

  def test_map_packer
    @test_map_packer ||= Tooling::TestMapPacker.new
  end
end

if __FILE__ == $PROGRAM_NAME
  merger = BackendTestMappingMerger.new
  success = merger.run
  exit(success ? 0 : 1)
end

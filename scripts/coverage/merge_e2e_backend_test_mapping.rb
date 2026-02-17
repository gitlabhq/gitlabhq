#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'zlib'
require 'stringio'
require 'fileutils'

require_relative '../../tooling/lib/tooling/test_map_packer'
require_relative 'path_normalizer'

# Merges E2E test mappings with Crystalball RSpec mappings.
#
# E2E mappings (test -> sources) are inverted to source -> tests format,
# then merged with Crystalball mappings to produce a combined mapping file.
#
# Crystalball provides two mapping strategies:
# - DescribedClassStrategy: Maps tests based on the described class (packed-mapping.json.gz)
# - CoverageStrategy: Maps tests based on actual code coverage (packed-mapping-alt.json.gz)
#
# Both strategies are merged to provide comprehensive test-to-source mappings.
class BackendTestMappingMerger
  CRYSTALBALL_DESCRIBED_MAPPING_PATH = 'crystalball/packed-mapping.json.gz'
  CRYSTALBALL_COVERAGE_MAPPING_PATH = 'crystalball/packed-mapping-alt.json.gz'
  MERGED_MAPPING_PATH = 'crystalball/merged-mapping.json.gz'
  E2E_MAPPING_ARTIFACT_GLOB = 'e2e-test-mapping/test-code-paths-mapping-*.json'

  def run
    puts "=== E2E Test Mapping Merger ==="

    e2e_mapping = load_e2e_mapping
    inverted_e2e_mapping = if e2e_mapping.nil? || e2e_mapping.empty?
                             puts "No E2E mappings found, will use Crystalball mapping only"
                             {}
                           else
                             inverted = invert_mapping(e2e_mapping)
                             puts "Inverted E2E mapping: #{inverted.size} source files"
                             inverted
                           end

    described_mapping = load_crystalball_mapping(CRYSTALBALL_DESCRIBED_MAPPING_PATH)
    if described_mapping.nil?
      puts "Crystalball described_class mapping not found at #{CRYSTALBALL_DESCRIBED_MAPPING_PATH}"
      described_mapping = {}
    else
      puts "Loaded Crystalball described_class mapping: #{described_mapping.size} source files"
    end

    coverage_mapping = load_crystalball_mapping(CRYSTALBALL_COVERAGE_MAPPING_PATH)
    if coverage_mapping.nil?
      puts "Crystalball coverage mapping not found at #{CRYSTALBALL_COVERAGE_MAPPING_PATH}"
      coverage_mapping = {}
    else
      puts "Loaded Crystalball coverage mapping: #{coverage_mapping.size} source files"
    end

    if inverted_e2e_mapping.empty? && described_mapping.empty? && coverage_mapping.empty?
      warn "ERROR: All mappings are missing, cannot produce merged mapping"
      return false
    end

    # Merge all mapping sources: described_class + coverage + e2e
    merged_mapping = merge_mappings(described_mapping, coverage_mapping)
    merged_mapping = merge_mappings(merged_mapping, inverted_e2e_mapping)
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
  # Also normalizes source file paths to ensure consistent format.
  def invert_mapping(test_to_sources)
    test_to_sources.each_with_object({}) do |(test_file, source_files), source_to_tests|
      Array(source_files).each do |source_file|
        # Normalize paths to handle absolute paths from Coverband and ./ prefix from Crystalball
        normalized_source = PathNormalizer.normalize(source_file)
        source_to_tests[normalized_source] ||= []
        source_to_tests[normalized_source] << test_file unless source_to_tests[normalized_source].include?(test_file)
      end
    end
  end

  # Loads and unpacks Crystalball mapping from gzipped file.
  def load_crystalball_mapping(path)
    return unless File.exist?(path)

    compressed = File.binread(path)
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

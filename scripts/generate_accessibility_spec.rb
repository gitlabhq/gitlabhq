#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'fileutils'

# Load helper classes
require_relative 'accessibility_generator/e2e_metadata_extractor'
require_relative 'accessibility_generator/feature_test_finder'
require_relative 'accessibility_generator/code_pattern_extractor'

class AccessibilitySpecGenerator
  GITLAB_ROOT = File.expand_path('..', __dir__)
  CONFIG_DIR = File.join(GITLAB_ROOT, 'config', 'accessibility_journeys')
  TEMPLATE_PATH = File.join(GITLAB_ROOT, 'scripts', 'templates', 'accessibility_spec_template.rb.erb')
  OUTPUT_DIR = File.join(GITLAB_ROOT, 'spec', 'features', 'accessibility')

  # Configuration constants
  MAX_FEATURE_TESTS = 10
  MAX_PATTERNS_PER_CATEGORY = 3
  MAX_LINE_LENGTH = 80
  TRUNCATION_SUFFIX = '...'

  # Word lists for filtering
  GENERIC_WORDS = %w[
    user users views test spec create show edit delete list index new update
    manage performs does has can will should verify check validate
  ].freeze

  MINIMAL_GENERIC_WORDS = %w[user users test spec].freeze

  def initialize(config_file)
    @config_file = config_file
    @config = load_config
  end

  def generate
    validate_config!

    puts "Generating accessibility spec for: #{@config['journey_name']}"
    puts "Stage: #{@config['stage']}"

    # Filter out tests without UI
    @e2e_tests = @config['e2e_test_files'].select { |test| test['has_ui'] }

    # Group by focus area
    @grouped_tests = @e2e_tests.group_by { |test| test['focus_area'] }

    puts "Found #{@e2e_tests.size} E2E tests with UI across #{@grouped_tests.size} focus areas"

    # Extract test case URLs from E2E files using MetadataExtractor
    metadata_extractor = E2EMetadataExtractor.new(GITLAB_ROOT)
    metadata_extractor.extract_metadata(@e2e_tests)

    # Find relevant feature test files using FeatureTestFinder
    feature_finder = FeatureTestFinder.new(GITLAB_ROOT, max_results: MAX_FEATURE_TESTS)
    @related_feature_tests = feature_finder.find_related_tests(@e2e_tests, @config)
    puts "Found #{@related_feature_tests.size} related feature test files"

    # Extract code patterns from feature tests using CodePatternExtractor
    pattern_extractor = CodePatternExtractor.new(GITLAB_ROOT)
    @code_patterns = pattern_extractor.extract_patterns(@related_feature_tests)
    puts "Extracted code patterns: #{@code_patterns['setup'].size} setup, " \
      "#{@code_patterns['navigation'].size} navigation, " \
      "#{@code_patterns['interaction'].size} interaction"

    # Generate the spec file
    output_path = generate_spec_file

    puts "\n✓ Generated: #{output_path}"
    puts "\nNext steps:"
    puts "  - Review the generated file"
    puts "  - Engineers should implement tests following the TODO comments"
    puts "  - Reference feature test files are listed at the top"

    output_path
  end

  private

  def load_config
    path = if File.exist?(@config_file)
             @config_file
           else
             File.join(CONFIG_DIR, @config_file)
           end

    YAML.safe_load_file(path)
  rescue Errno::ENOENT
    abort "Error: Config file not found: #{@config_file}"
  rescue Psych::SyntaxError => e
    abort "Error: Invalid YAML in config file: #{e.message}"
  end

  def validate_config!
    required_fields = %w[stage journey_name feature_category e2e_test_files]
    missing_fields = required_fields - @config.keys

    abort "Error: Missing required fields: #{missing_fields.join(', ')}" if missing_fields.any?
    abort "Error: No E2E test files defined" if @config['e2e_test_files'].empty?
  end

  def generate_spec_file
    template = ERB.new(File.read(TEMPLATE_PATH), trim_mode: '-')

    # Prepare template context with all variables needed by ERB
    template_context = TemplateContext.new(
      stage: @config['stage'],
      journey_name: @config['journey_name'],
      feature_category: @config['feature_category'],
      description: @config['description'],
      grouped_tests: @grouped_tests,
      related_feature_tests: @related_feature_tests,
      code_patterns: @code_patterns
    )

    output = template.result(template_context.get_binding)

    # Write to file
    output_path = File.join(OUTPUT_DIR, template_context.stage, "#{template_context.journey_name}_spec.rb")
    FileUtils.mkdir_p(File.dirname(output_path))
    File.write(output_path, output)

    output_path
  end
end

# Template context class to hold variables for ERB binding
class TemplateContext
  attr_reader :stage, :journey_name, :journey_title, :feature_category,
    :description, :grouped_tests, :related_feature_tests, :code_patterns

  def initialize(
    stage:, journey_name:, feature_category:, description:, grouped_tests:, related_feature_tests:,
    code_patterns:)
    @stage = stage
    @journey_name = journey_name
    @journey_title = journey_name.split('_').map(&:capitalize).join(' ')
    @feature_category = feature_category
    @description = description
    @grouped_tests = grouped_tests
    @related_feature_tests = related_feature_tests
    @code_patterns = code_patterns
  end

  def get_binding
    binding
  end
end

# CLI interface
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: #{$PROGRAM_NAME} <config_file>"
    puts ""
    puts "Example:"
    puts "  #{$PROGRAM_NAME} create_writing_code.yml"
    puts "  #{$PROGRAM_NAME} config/accessibility_journeys/create_writing_code.yml"
    exit 1
  end

  generator = AccessibilitySpecGenerator.new(ARGV[0])
  generator.generate
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parallel'
require 'rainbow'
require 'yaml'

module Lint
  class UnusedScopes
    EXCLUDED_SCOPES_PATH = 'scripts/lint/excluded_scopes.yml'
    POTENTIAL_SCOPES_PATH = 'scripts/lint/potential_scopes_to_remove.yml'

    # File extensions to scan for scope calls.
    # Includes .builder for Atom feed templates (e.g., app/views/events/_event.atom.builder)
    #
    EXTENSIONS = %w[rb haml erb builder].freeze

    # Directory patterns to scan
    #
    DIRECTORY_PATTERNS = %w[
      {ee/,}app/**/*.%<ext>s
      config/**/*.%<ext>s
      gems/**/*.%<ext>s
      {ee/,}lib/**/*.%<ext>s
    ].freeze

    # Patterns for files that define scopes we want to check.
    # Scopes are only defined in model files and concerns.
    #
    SCOPE_DEFINITION_PATTERNS = %r{app/models}

    attr_reader :source_files, :unused_scope_collection, :new_unused_scopes, :removed_scopes

    def initialize(
      excluded_scopes_path: EXCLUDED_SCOPES_PATH,
      potential_scopes_path: POTENTIAL_SCOPES_PATH,
      extensions: EXTENSIONS
    )
      @excluded_scopes_path = excluded_scopes_path
      @potential_scopes_path = potential_scopes_path
      @extensions = extensions
      @source_files = {}
      @unused_scope_collection = Hash.new { |hash, key| hash[key] = [] }
      @new_unused_scopes = []
      @removed_scopes = []
    end

    def run(print_report: false, update_yaml: false)
      return false unless ee_directory_exists?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      load_source_files
      scopes = find_defined_scopes
      scopes = filter_excluded_scopes(scopes)

      puts "Scanning #{source_files.size} files for #{scopes.size} scopes..." if print_report

      find_unused_scopes(scopes, print_report: print_report)

      if print_report
        print_full_report(start)
        write_potential_scopes_file if update_yaml
        return true
      end

      compare_with_known_scopes
      print_diff_report

      new_unused_scopes.empty? && removed_scopes.empty?
    end

    def file_extensions_glob
      @extensions.flat_map do |ext|
        DIRECTORY_PATTERNS.map { |pattern| format(pattern, ext: ext) }
      end
    end

    def ee_directory_exists?
      Dir.exist?('ee')
    end

    private

    # Indents YAML list items that are not already indented.
    # Ruby's to_yaml outputs list items without indentation (e.g., "- item"),
    # but our YAML files use 2-space indentation (e.g., "  - item").
    #
    def indent_yaml_list_items(yaml_string)
      yaml_string.gsub(/\n-(\s+\S)/, "\n  -\\1")
    end

    def write_potential_scopes_file
      return if unused_scope_collection.empty?

      yaml_content = indent_yaml_list_items(unused_scope_collection.to_yaml)
      File.write(@potential_scopes_path, yaml_content)
      puts Rainbow("Updated #{@potential_scopes_path}").green.bright
    end

    def load_source_files
      Dir.glob(file_extensions_glob).each do |filename|
        @source_files[filename] = File.readlines(filename)
      end
    end

    def find_defined_scopes
      source_files.keys.grep(SCOPE_DEFINITION_PATTERNS).flat_map do |filename|
        source_files[filename].flat_map do |line|
          # Match scope definitions but not default_scope or commented lines.
          # Pattern: scope :name, -> { } or scope :name, ->(args) do
          #
          next [] if line.strip.start_with?('#')

          line =~ /\bscope\s+:(\w+)/ ? [{ scope: Regexp.last_match(1), file: filename }] : []
        end
      end
    end

    def filter_excluded_scopes(scopes)
      return scopes unless File.exist?(@excluded_scopes_path)

      excluded_scopes = YAML.load_file(@excluded_scopes_path, symbolize_names: true) || {}

      scopes.reject do |h|
        excluded_scope = excluded_scopes[h[:file].to_sym]
        excluded_scope&.flat_map(&:keys)&.include?(h[:scope].to_sym)
      end
    end

    def find_unused_scopes(scopes, print_report: false)
      source_code = source_files.values.flatten.join

      unused = Parallel.flat_map(scopes, progress: ('Checking scopes' if print_report)) do |scope|
        regex = build_usage_regex(scope[:scope])
        regex.match?(source_code) ? [] : scope
      end

      unused.each do |unused_scope|
        @unused_scope_collection[unused_scope[:file]] << unused_scope[:scope]
      end
    end

    def build_usage_regex(scope_name)
      # Match scope usage but not:
      # - scope definitions (scope :name)
      # - method definitions (def name)
      #
      /(?<!scope :)(?<!def )#{Regexp.quote(scope_name)}\W/
    end

    def compare_with_known_scopes
      return unless File.exist?(@potential_scopes_path)

      potential_unused = YAML.load_file(@potential_scopes_path) || {}
      potential_scopes = potential_unused.flat_map { |f, sl| [f].product(sl) }

      current_unused = unused_scope_collection.flat_map { |f, sl| [f].product(sl) }

      @new_unused_scopes = current_unused - potential_scopes
      @removed_scopes = potential_scopes - current_unused
    end

    def print_full_report(start)
      finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      unused_count = unused_scope_collection.values.flatten.size

      if unused_count > 0
        puts "\nFound #{unused_count} unused scopes:\n\n"
        puts indent_yaml_list_items(unused_scope_collection.to_yaml)
        puts "\n"
      else
        puts Rainbow('No unused scopes were found.').green.bright
      end

      puts "Finished in #{finish - start} seconds."
    end

    def print_diff_report
      print_new_unused_scopes unless new_unused_scopes.empty?

      if new_unused_scopes.size + removed_scopes.size > 0
        puts Rainbow("~" * 80).white.bright
        puts "\n"
      end

      print_removed_scopes unless removed_scopes.empty?
    end

    def print_new_unused_scopes
      error = <<~UPDATE_UNUSED
        #{Rainbow('ERROR').red.bright} We have detected #{new_unused_scopes.size} newly unused scopes.

        Please remove these scopes, or if in use, add to #{@excluded_scopes_path}.\n
      UPDATE_UNUSED

      puts Rainbow(error).red.bright
      puts Rainbow(indent_yaml_list_items(parse_scopes_diff(new_unused_scopes).to_yaml)).red.bright
    end

    def print_removed_scopes
      warning = <<~UPDATE_UNUSED
        #{Rainbow('SUCCESS').green.bright} It appears you have removed unused scopes. Thank you!

        Please update potential_scopes_to_remove.yml and remove entries for these scopes.\n
      UPDATE_UNUSED

      print Rainbow(warning).yellow.bright
      puts Rainbow(indent_yaml_list_items(parse_scopes_diff(removed_scopes).to_yaml)).yellow.bright
    end

    def parse_scopes_diff(diff_to_parse)
      scopes_hash = Hash.new { |hash, key| hash[key] = [] }

      diff_to_parse.each do |file_name, scope_name|
        scopes_hash[file_name] << scope_name
      end

      scopes_hash
    end
  end
end

# Run the script if executed directly
if $PROGRAM_NAME == __FILE__
  print_report = %w[true 1].include?(ENV["REPORT_ALL_UNUSED_SCOPES"])
  update_yaml = %w[true 1].include?(ENV["UPDATE_YAML"])
  linter = Lint::UnusedScopes.new
  success = linter.run(print_report: print_report, update_yaml: update_yaml)
  exit(success ? 0 : 1)
end

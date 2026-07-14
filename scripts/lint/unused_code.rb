#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parallel'
require 'rainbow'
require 'yaml'

module Lint
  # Base class for detecting unused code patterns (methods, scopes, etc.)
  #
  # This consolidates the shared logic from unused_methods.rb and unused_scopes.rb
  # into a single configurable scanner. Each "type" of unused code detection is
  # implemented as a strategy that defines:
  #   - How to find definitions (regex pattern)
  #   - Where to look for definitions (file patterns)
  #   - How to detect usage (regex builder)
  #   - YAML file paths for tracking
  #
  # Usage:
  #   # Scan for all types (default) - CI mode, compares against baseline
  #   ruby scripts/lint/unused_code.rb
  #
  #   # Scan for unused methods only
  #   ruby scripts/lint/unused_code.rb --type methods
  #
  #   # Scan for unused scopes only
  #   ruby scripts/lint/unused_code.rb --type scopes
  #
  #   # Report mode (full scan, shows all unused code)
  #   ruby scripts/lint/unused_code.rb --report
  #
  #   # Update YAML baseline (implies --report)
  #   ruby scripts/lint/unused_code.rb --update-yaml
  #
  class UnusedCode
    # File extensions to scan for code usage.
    # Includes .builder for Atom feed templates (e.g., app/views/events/_event.atom.builder)
    #
    EXTENSIONS = %w[rb haml erb builder].freeze

    # Directory patterns to scan for usage
    #
    DIRECTORY_PATTERNS = %w[
      {ee/,}app/**/*.%<ext>s
      config/**/*.%<ext>s
      gems/**/*.%<ext>s
      {ee/,}lib/**/*.%<ext>s
    ].freeze

    # Strategy definitions for each type of unused code detection
    #
    STRATEGIES = {
      methods: {
        name: 'methods',
        excluded_path: 'scripts/lint/excluded_methods.yml',
        potential_path: 'scripts/lint/potential_methods_to_remove.yml',
        definition_patterns: %r{app/helpers|app/models},
        definition_regex: ->(line) { line =~ /def ([^(;\s]+)/ ? Regexp.last_match(1).chomp : nil },
        skip_commented: false,
        usage_regex: ->(name) {
          if name.end_with?('=')
            /(?<!def )#{Regexp.quote(name.sub(/^self\./, '').chomp('='))}\W=*/
          else
            /(?<!def )#{Regexp.quote(name.sub(/^self\./, ''))}\W/
          end
        }
      },
      scopes: {
        name: 'scopes',
        excluded_path: 'scripts/lint/excluded_scopes.yml',
        potential_path: 'scripts/lint/potential_scopes_to_remove.yml',
        definition_patterns: %r{app/models},
        definition_regex: ->(line) { line =~ /\bscope\s+:(\w+)/ ? Regexp.last_match(1) : nil },
        skip_commented: true,
        usage_regex: ->(name) { /(?<!scope :)(?<!def )#{Regexp.quote(name)}\W/ }
      }
    }.freeze

    attr_reader :source_files, :unused_collection, :new_unused, :removed, :strategy

    def initialize(
      type: :methods,
      extensions: EXTENSIONS
    )
      @strategy = STRATEGIES.fetch(type) do
        raise ArgumentError, "Unknown type: #{type}. Valid: #{STRATEGIES.keys.join(', ')}"
      end
      @extensions = extensions
      @source_files = {}
      @unused_collection = Hash.new { |hash, key| hash[key] = [] }
      @new_unused = []
      @removed = []
    end

    def run(print_report: false, update_yaml: false)
      return true unless ee_directory_exists?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      load_source_files
      definitions = find_definitions
      definitions = filter_excluded(definitions)

      puts "Scanning #{source_files.size} files for #{definitions.size} #{strategy[:name]}..." if print_report

      find_unused(definitions, print_report: print_report)

      if print_report
        print_full_report(start)
        write_potential_file if update_yaml
        return true
      end

      compare_with_known
      print_diff_report

      new_unused.empty? && removed.empty?
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

    def write_potential_file
      header = <<~HEADER
        # The #{strategy[:name]} listed here have been identified as "unused" by the linter
        #   scripts/lint/unused_code.rb --type #{strategy[:name]}, and are potential targets for future
        #   removal.
        #
        # If it turns out that a #{strategy[:name].chomp('s')} you are attempting to remove is in fact in use,
        #   remove it from this file and add it to `excluded_#{strategy[:name]}.yml`.
        #
      HEADER

      yaml_content = if unused_collection.empty?
                       "#{header}---\n{}\n"
                     else
                       sorted_collection = unused_collection.sort.to_h
                       "#{header}#{indent_yaml_list_items(sorted_collection.to_yaml)}"
                     end

      File.write(strategy[:potential_path], yaml_content)
      puts Rainbow("Updated #{strategy[:potential_path]}").green.bright
    end

    def load_source_files
      Dir.glob(file_extensions_glob).each do |filename|
        @source_files[filename] = File.readlines(filename)
      end
    end

    def find_definitions
      source_files.keys.grep(strategy[:definition_patterns]).flat_map do |filename|
        source_files[filename].flat_map do |line|
          next [] if strategy[:skip_commented] && line.strip.start_with?('#')

          name = strategy[:definition_regex].call(line)
          name ? [{ name: name, file: filename }] : []
        end
      end
    end

    # Filter out definitions that are in the excluded YAML file.
    # Expected YAML format:
    #   path/to/file.rb:
    #     - method_name: "Reason for exclusion"
    #     - other_method: "Another reason"
    #
    def filter_excluded(definitions)
      return definitions unless File.exist?(strategy[:excluded_path])

      excluded = YAML.load_file(strategy[:excluded_path], symbolize_names: true) || {}

      definitions.reject do |h|
        excluded_for_file = excluded[h[:file].to_sym]
        excluded_for_file&.flat_map(&:keys)&.include?(h[:name].to_sym)
      end
    end

    def find_unused(definitions, print_report: false)
      source_code = source_files.values.flatten.join

      unused = Parallel.flat_map(definitions, progress: ("Checking #{strategy[:name]}" if print_report)) do |definition|
        regex = strategy[:usage_regex].call(definition[:name])
        regex.match?(source_code) ? [] : definition
      end

      unused.each do |unused_def|
        @unused_collection[unused_def[:file]] << unused_def[:name]
      end
    end

    def compare_with_known
      unless File.exist?(strategy[:potential_path])
        warn Rainbow(
          "Warning: #{strategy[:potential_path]} not found. Run with --update-yaml to generate it."
        ).yellow
        return
      end

      potential_unused = YAML.load_file(strategy[:potential_path]) || {}
      potential = potential_unused.flat_map { |f, names| [f].product(names) }

      current = unused_collection.flat_map { |f, names| [f].product(names) }

      @new_unused = current - potential
      @removed = potential - current
    end

    def print_full_report(start)
      finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      unused_count = unused_collection.values.flatten.size

      if unused_count > 0
        puts "\nFound #{unused_count} unused #{strategy[:name]}:\n\n"
        puts indent_yaml_list_items(unused_collection.to_yaml)
        puts "\n"
      else
        puts Rainbow("No unused #{strategy[:name]} were found.").green.bright
      end

      puts "Finished in #{finish - start} seconds."
    end

    def print_diff_report
      print_new_unused unless new_unused.empty?

      if new_unused.size + removed.size > 0
        puts Rainbow("~" * 80).white.bright
        puts "\n"
      end

      print_removed unless removed.empty?
    end

    def print_new_unused
      error = <<~UPDATE_UNUSED
        ❌ We have detected #{new_unused.size} newly unused #{strategy[:name]}.

        Please remove these #{strategy[:name]}, or if in use, add to #{strategy[:excluded_path]}.\n
      UPDATE_UNUSED

      puts Rainbow(error).red.bright
      puts Rainbow(indent_yaml_list_items(parse_diff(new_unused).to_yaml)).red.bright
    end

    def print_removed
      warning = <<~UPDATE_UNUSED
        🏆 It appears you have removed unused #{strategy[:name]}. Thank you!

        Please update #{File.basename(strategy[:potential_path])} and remove entries for these #{strategy[:name]}.\n
      UPDATE_UNUSED

      print Rainbow(warning).yellow.bright
      puts Rainbow(indent_yaml_list_items(parse_diff(removed).to_yaml)).yellow.bright
    end

    def parse_diff(diff_to_parse)
      result = Hash.new { |hash, key| hash[key] = [] }

      diff_to_parse.each do |file_name, name|
        result[file_name] << name
      end

      result
    end
  end
end

# Run the script if executed directly
if $PROGRAM_NAME == __FILE__
  require 'optparse'

  options = { type: :all, report: false, update_yaml: false }

  OptionParser.new do |opts|
    opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

    opts.on('--type TYPE', %i[methods scopes all], 'Type to detect: methods, scopes, all (default: all)') do |type|
      options[:type] = type
    end

    opts.on('--report', '-r', 'Report mode: show all unused code (no diff comparison)') do
      options[:report] = true
    end

    opts.on('--update-yaml', '-u', 'Update the YAML baseline file (implies --report)') do
      options[:update_yaml] = true
      options[:report] = true
    end

    opts.on('-h', '--help', 'Show this help') do
      puts opts
      exit
    end
  end.parse!

  print_report = options[:report]
  update_yaml = options[:update_yaml]

  types = options[:type] == :all ? %i[methods scopes] : [options[:type]]
  success = true

  types.each do |type|
    puts Rainbow("=== Checking unused #{type} ===").cyan.bright if types.size > 1
    linter = Lint::UnusedCode.new(type: type)
    success &&= linter.run(print_report: print_report, update_yaml: update_yaml)
    puts if types.size > 1
  end

  exit(success ? 0 : 1)
end

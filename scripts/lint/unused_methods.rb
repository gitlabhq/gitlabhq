#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parallel'
require 'rainbow'
require 'yaml'

module Lint
  class UnusedMethods
    EXCLUDED_METHODS_PATH = 'scripts/lint/excluded_methods.yml'
    POTENTIAL_METHODS_PATH = 'scripts/lint/potential_methods_to_remove.yml'

    # File extensions to scan for method calls.
    # Includes .builder for Atom feed templates (e.g., app/views/events/_event.atom.builder)
    EXTENSIONS = %w[rb haml erb builder].freeze

    # Directory patterns to scan
    DIRECTORY_PATTERNS = %w[
      {ee/,}app/**/*.%<ext>s
      config/**/*.%<ext>s
      gems/**/*.%<ext>s
      {ee/,}lib/**/*.%<ext>s
    ].freeze

    # Patterns for files that define methods we want to check
    METHOD_DEFINITION_PATTERNS = %r{app/helpers|app/models}

    attr_reader :source_files, :unused_method_collection, :new_unused_methods, :removed_methods

    def initialize(
      excluded_methods_path: EXCLUDED_METHODS_PATH,
      potential_methods_path: POTENTIAL_METHODS_PATH,
      extensions: EXTENSIONS
    )
      @excluded_methods_path = excluded_methods_path
      @potential_methods_path = potential_methods_path
      @extensions = extensions
      @source_files = {}
      @unused_method_collection = Hash.new { |hash, key| hash[key] = [] }
      @new_unused_methods = []
      @removed_methods = []
    end

    def run(print_report: false)
      return false unless ee_directory_exists?

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      load_source_files
      methods = find_defined_methods
      methods = filter_excluded_methods(methods)

      puts "Scanning #{source_files.size} files for #{methods.size} methods..." if print_report

      find_unused_methods(methods, print_report: print_report)

      if print_report
        print_full_report(start)
        return true
      end

      compare_with_known_methods
      print_diff_report

      new_unused_methods.empty? && removed_methods.empty?
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

    def load_source_files
      Dir.glob(file_extensions_glob).each do |filename|
        @source_files[filename] = File.readlines(filename)
      end
    end

    def find_defined_methods
      source_files.keys.grep(METHOD_DEFINITION_PATTERNS).flat_map do |filename|
        source_files[filename].flat_map do |line|
          line =~ /def ([^(;\s]+)/ ? [{ method: Regexp.last_match(1).chomp, file: filename }] : []
        end
      end
    end

    def filter_excluded_methods(methods)
      return methods unless File.exist?(@excluded_methods_path)

      excluded_methods = YAML.load_file(@excluded_methods_path, symbolize_names: true)

      methods.reject do |h|
        excluded_method = excluded_methods[h[:file].to_sym]
        excluded_method&.flat_map(&:keys)&.include?(h[:method].to_sym)
      end
    end

    def find_unused_methods(methods, print_report: false)
      source_code = source_files.values.flatten.join

      unused = Parallel.flat_map(methods, progress: ('Checking methods' if print_report)) do |method|
        regex = build_usage_regex(method[:method])
        regex.match?(source_code) ? [] : method
      end

      unused.each do |unused_method|
        @unused_method_collection[unused_method[:file]] << unused_method[:method]
      end
    end

    def build_usage_regex(method_name)
      if method_name.end_with?('=')
        /(?<!def )#{Regexp.quote(method_name.sub(/^self\./, '').chomp('='))}\W=*/
      else
        /(?<!def )#{Regexp.quote(method_name.sub(/^self\./, ''))}\W/
      end
    end

    def compare_with_known_methods
      return unless File.exist?(@potential_methods_path)

      potential_unused = YAML.load_file(@potential_methods_path)
      potential_methods = potential_unused.flat_map { |f, ml| [f].product(ml) }

      current_unused = unused_method_collection.flat_map { |f, ml| [f].product(ml) }

      @new_unused_methods = current_unused - potential_methods
      @removed_methods = potential_methods - current_unused
    end

    def print_full_report(start)
      finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      unused_count = unused_method_collection.values.flatten.size

      if unused_count > 0
        puts "\nFound #{unused_count} unused methods:\n\n"
        puts unused_method_collection.to_yaml
        puts "\n"
      else
        puts Rainbow('No unused methods were found.').green.bright
      end

      puts "Finished in #{finish - start} seconds."
    end

    def print_diff_report
      print_new_unused_methods unless new_unused_methods.empty?

      if new_unused_methods.size + removed_methods.size > 0
        puts Rainbow("~" * 80).white.bright
        puts "\n"
      end

      print_removed_methods unless removed_methods.empty?
    end

    def print_new_unused_methods
      error = <<~UPDATE_UNUSED
        ❌ We have detected #{new_unused_methods.size} newly unused methods.

        Please remove these methods, or if in use, add to #{@excluded_methods_path}.\n
      UPDATE_UNUSED

      puts Rainbow(error).red.bright
      puts Rainbow(parse_methods_diff(new_unused_methods).to_yaml).red.bright
    end

    def print_removed_methods
      warning = <<~UPDATE_UNUSED
        🏆 It appears you have removed unused methods. Thank you!

        Please update potential_methods_to_remove.yml and remove entries for these methods.\n
      UPDATE_UNUSED

      print Rainbow(warning).yellow.bright
      puts Rainbow(parse_methods_diff(removed_methods).to_yaml).yellow.bright
    end

    def parse_methods_diff(diff_to_parse)
      methods_hash = Hash.new { |hash, key| hash[key] = [] }

      diff_to_parse.each do |file_name, method_name|
        methods_hash[file_name] << method_name
      end

      methods_hash
    end
  end
end

# Run the script if executed directly
if $PROGRAM_NAME == __FILE__
  print_report = %w[true 1].include?(ENV["REPORT_ALL_UNUSED_METHODS"])
  linter = Lint::UnusedMethods.new
  success = linter.run(print_report: print_report)
  exit(success ? 0 : 1)
end

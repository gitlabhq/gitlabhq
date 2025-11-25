#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parallel'
require 'rainbow'
require 'yaml'

EXCLUDED_METHODS_PATH = '.gitlab/lint/unused_methods/excluded_methods.yml'
POTENTIAL_METHODS_PATH = '.gitlab/lint/unused_methods/potential_methods_to_remove.yml'

print_output = %w[true 1].include? ENV["REPORT_ALL_UNUSED_METHODS"]

start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# Build an array of filename globs to process.
# Only search file types that might use or define a method.
#
extensions = %w[rb haml erb].flat_map { |ext| ["{ee/,}app/**/*.#{ext}", "{ee/,}lib/**/*.#{ext}"] }

# Build a hash of all the source files to search.
# Key is filename, value is an array of the lines.
#
source_files = {}

Dir.glob(extensions).each do |filename|
  source_files[filename] = File.readlines(filename)
end

# Build an array of {method, file} hashes defined in [ee/]app/helpers/* and
#   [ee/]app/models/* files.
#
methods = source_files.keys.grep(%r{app/helpers|app/models}).flat_map do |filename|
  source_files[filename].flat_map do |line|
    line =~ /def ([^(;\s]+)/ ? [{ method: Regexp.last_match(1).chomp, file: filename }] : []
  end
end

# Remove any excluded methods
#
excluded_methods = YAML.load_file(EXCLUDED_METHODS_PATH, symbolize_names: true)

methods.reject! do |h|
  excluded_methods.dig(h[:method].to_sym, :file) == h[:file]
end

puts "Scanning #{source_files.size} files for #{methods.size} methods..." if print_output

# Combine all the source code into one big string, because regex are fast.
#
source_code = source_files.values.flatten.join

# Iterate over all the methods and reject any that appear anywhere in the complete source.
#
unused = Parallel.flat_map(methods, progress: ('Checking methods' if print_output)) do |method|
  regex = if method[:method].end_with?('=')
            /(?<!def )#{Regexp.quote(method[:method].sub(/^self\./, '').chomp('='))}\W=*/
          else
            /(?<!def )#{Regexp.quote(method[:method].sub(/^self\./, ''))}\W/
          end

  regex.match?(source_code) ? [] : method
end

if print_output
  finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  if unused
    puts "\nFound #{unused.size} unused methods:\n\n"
    unused.each { |unused_method| puts "  - [ ] `#{unused_method[:file]}`: `#{unused_method[:method]}`" }
    puts "\n"
  else
    puts Rainbow('No unused methods were found.').green.bright
  end

  puts "Finished in #{finish - start} seconds."
  exit 0
end

potential_methods = YAML.load_file(POTENTIAL_METHODS_PATH, symbolize_names: true)
potential_methods_count = potential_methods.size

current_unused_names = unused.collect { |entry| entry[:method].to_sym }.uniq

if current_unused_names.size > potential_methods_count
  added_count = current_unused_names.size - potential_methods_count

  new_unused_method_names = current_unused_names - potential_methods.keys
  newly_unused = unused.select { |entry| new_unused_method_names.include? entry[:method].to_sym }

  puts Rainbow("❌ We have detected #{added_count} newly unused methods. They are:\n").red.bright

  newly_unused.each do |newly_unused_method|
    puts Rainbow("#{newly_unused_method[:method]}:").red.bright
    puts Rainbow("  file: #{newly_unused_method[:file]}").red.bright
    puts Rainbow("  reason:").red.bright
  end

  puts Rainbow("\nPlease remove these methods, or if in use, add to #{EXCLUDED_METHODS_PATH}.").red.bright

  exit 1
elsif unused.size < potential_methods_count
  removed_method_names = potential_methods.keys - unused.collect { |h| h[:method].to_sym }
  removed = potential_methods.select { |k, _| removed_method_names.include?(k) }

  warning = <<~UPDATE_UNUSED
  🏆 It appears you have removed unused methods. Thank you!

  Please update potential_methods_to_remove.yml and remove entries for these methods.\n
  UPDATE_UNUSED

  print Rainbow(warning).yellow.bright

  removed.each do |k, v|
    puts Rainbow("#{k}:").yellow.bright
    puts Rainbow("  file: #{v[:file]}").yellow.bright
  end

  exit 1
end

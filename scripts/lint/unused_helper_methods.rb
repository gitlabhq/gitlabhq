#!/usr/bin/env ruby
# frozen_string_literal: true

# Inspired in part by https://gist.github.com/kylefox/617b0bead5f53dc53a224a8651328c92
#

require 'parallel'
require 'rainbow'
require 'yaml'

EXCLUDED_METHODS_PATH = '.gitlab/lint/unused_helper_methods/excluded_methods.yml'
POTENTIAL_METHODS_PATH = '.gitlab/lint/unused_helper_methods/potential_methods_to_remove.yml'

print_output = %w[true 1].include? ENV["REPORT_ALL_UNUSED_METHODS"]

start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# Build an array of filename globs to process.
# Only search file types that might use or define a helper.
#
extensions = %w[rb haml erb].flat_map { |ext| ["{ee/,}app/**/*.#{ext}", "{ee/,}lib/**/*.#{ext}"] }

# Build a hash of all the source files to search.
# Key is filename, value is an array of the lines.
#
source_files = {}

Dir.glob(extensions).each do |filename|
  source_files[filename] = File.readlines(filename)
end

# Build an array of {method, file} hashes defined in app/helper/* files.
#
helpers = source_files.keys.grep(%r{app/helpers}).flat_map do |filename|
  source_files[filename].flat_map do |line|
    line =~ /def ([^(;\s]+)/ ? [{ method: Regexp.last_match(1).chomp, file: filename }] : []
  end
end

# Remove any excluded methods
#
excluded_methods = YAML.load_file(EXCLUDED_METHODS_PATH, symbolize_names: true)

helpers.reject! do |h|
  excluded_methods.dig(h[:method].to_sym, :file) == h[:file]
end

puts "Scanning #{source_files.size} files for #{helpers.size} helpers..." if print_output

# Combine all the source code into one big string, because regex are fast.
#
source_code = source_files.values.flatten.join

# Iterate over all the helpers and reject any that appear anywhere in the complete source.
#
unused = Parallel.flat_map(helpers, progress: ('Checking helpers' if print_output)) do |helper|
  /(?<!def )#{Regexp.quote(helper[:method].sub(/^self\./, ''))}\W/.match?(source_code) ? [] : helper
end

if print_output
  finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  if unused
    puts "\nFound #{unused.size} unused helpers:\n\n"
    unused.each { |helper| puts "  - [ ] `#{helper[:file]}`: `#{helper[:method]}`" }
    puts "\n"
  else
    puts Rainbow('No unused helpers were found.').green.bright
  end

  puts "Finished in #{finish - start} seconds."
  exit 0
end

potential_methods = YAML.load_file(POTENTIAL_METHODS_PATH, symbolize_names: true)
potential_methods_count = potential_methods.size

if unused.size > potential_methods_count
  added_count = unused.size - potential_methods_count

  current_unused_names = unused.collect { |entry| entry[:method].to_sym }
  new_unused_method_names = current_unused_names - potential_methods.keys
  newly_unused = unused.select { |entry| new_unused_method_names.include? entry[:method].to_sym }

  puts Rainbow("❌ We have detected #{added_count} newly unused methods. They are:\n").red.bright

  newly_unused.each do |helper|
    puts Rainbow("#{helper[:method]}:").red.bright
    puts Rainbow("  file: #{helper[:file]}").red.bright
    puts Rainbow("  reason:").red.bright
  end

  puts Rainbow("\nPlease remove these methods, or if in use, add to #{EXCLUDED_METHODS_PATH}.").red.bright

  exit 1
elsif unused.size < potential_methods_count
  warning = <<~UPDATE_UNUSED
  🏆 It appears you have removed unused methods. Thank you!

  Please update potential_methods_to_remove.yml with the current list of unused methods.
  UPDATE_UNUSED

  print Rainbow(warning).yellow.bright

  exit 1
end

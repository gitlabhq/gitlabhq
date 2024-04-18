#!/usr/bin/env ruby
# frozen_string_literal: true

# Inspired in part by https://gist.github.com/kylefox/617b0bead5f53dc53a224a8651328c92
#

require 'parallel'
require 'rainbow'

UNUSED_METHODS = 51

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
    line =~ /def ([^(\s]+)/ ? [{ method: Regexp.last_match(1).chomp, file: filename }] : []
  end
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

if unused.size > UNUSED_METHODS
  added = unused.size - UNUSED_METHODS
  puts Rainbow("ERROR: #{added} unused methods were added. Please remove them.").red.bright

  exit 1
elsif unused.size < UNUSED_METHODS
  warning = <<~UPDATE_UNUSED
  WARNING: It appears you have removed unused methods. Thank you!

  Please update scripts/lint/unused_helper_methods.rb to reflect the new number:
  UNUSED_METHODS = #{unused.size}
  UPDATE_UNUSED

  puts Rainbow(warning).yellow.bright
end

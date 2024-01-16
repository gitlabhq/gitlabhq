#!/usr/bin/env ruby
# frozen_string_literal: true

# Inspired in part by https://gist.github.com/kylefox/617b0bead5f53dc53a224a8651328c92
#

require 'parallel'

start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# Build an array of filename globs to process.
# Only search file types that might use or define a helper.
#
extensions = %w[rb haml erb].map { |ext| "{ee/,}app/**/*.#{ext}" }

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

puts "Scanning #{source_files.size} files for #{helpers.size} helpers..."

# Combine all the source code into one big string, because regex are fast.
#
source_code = source_files.values.flatten.join

# Iterate over all the helpers and reject any that appear anywhere in the complete source.
#
unused = Parallel.flat_map(helpers, progress: 'Checking helpers') do |helper|
  /(?<!def )#{Regexp.quote(helper[:method].sub(/^self\./, ''))}\W/.match?(source_code) ? [] : helper
end

finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)

if unused
  puts "\nFound #{unused.size} unused helpers:\n\n"
  unused.each { |helper| puts "  - [ ] `#{helper[:file]}`: `#{helper[:method]}`" }
  puts "\n"
else
  puts 'No unused helpers were found.'
end

puts "Finished in #{finish - start} seconds."

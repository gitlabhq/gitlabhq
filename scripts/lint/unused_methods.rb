#!/usr/bin/env ruby
# frozen_string_literal: true

require 'parallel'
require 'rainbow'
require 'yaml'

EXCLUDED_METHODS_PATH = '.gitlab/lint/unused_methods/excluded_methods.yml'
POTENTIAL_METHODS_PATH = '.gitlab/lint/unused_methods/potential_methods_to_remove.yml'

print_report = %w[true 1].include? ENV["REPORT_ALL_UNUSED_METHODS"]

start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# Build an array of filename globs to process.
# Only search file types that might use or define a method.
#
extensions = %w[rb haml erb].flat_map do |ext|
  [
    "{ee/,}app/**/*.#{ext}",
    "config/**/*.#{ext}",
    "gems/**/*.#{ext}",
    "{ee/,}lib/**/*.#{ext}"
  ]
end

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
  excluded_method = excluded_methods[h[:file].to_sym]
  excluded_method.flat_map(&:keys).include?(h[:method].to_sym) if excluded_method
end

puts "Scanning #{source_files.size} files for #{methods.size} methods..." if print_report

# Combine all the source code into one big string, because regex are fast.
#
source_code = source_files.values.flatten.join

# Iterate over all the methods and reject any that appear anywhere in the complete source.
#
unused = Parallel.flat_map(methods, progress: ('Checking methods' if print_report)) do |method|
  regex = if method[:method].end_with?('=')
            /(?<!def )#{Regexp.quote(method[:method].sub(/^self\./, '').chomp('='))}\W=*/
          else
            /(?<!def )#{Regexp.quote(method[:method].sub(/^self\./, ''))}\W/
          end

  regex.match?(source_code) ? [] : method
end

# Transform used into a hash keyed on file names
#
unused_method_collection = Hash.new { |hash, key| hash[key] = [] }

unused.each do |unused_method|
  unused_method_collection[unused_method[:file]] << unused_method[:method]
end

# Print the list of all methods identified as unused as YAML.
#
if print_report
  finish = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  if unused
    puts "\nFound #{unused.size} unused methods:\n\n"

    puts unused_method_collection.to_yaml
    puts "\n"
  else
    puts Rainbow('No unused methods were found.').green.bright
  end

  puts "Finished in #{finish - start} seconds."
  exit 0
end

########################################################################################
# To report new unused or removed methods, build an array of `[file name]#[method name]`
#   for each set of methods, those in POTENTIAL_METHODS_PATH and those we stored
#   in unused_method_collection earlier. This gives each method a unique fingerprint.
#   We then find the difference between between these 2 arrays in each direction,
#   which gives us a list of newly unused methods as well as those that appear to
#   have been removed from the application.
#
def parse_methods_diff(diff_to_parse)
  methods_hash = Hash.new { |hash, key| hash[key] = [] }

  diff_to_parse.each do |file_name, method_name|
    methods_hash[file_name] << method_name
  end

  methods_hash
end

# Create arrays of "[file name], [method name]" for comparison
#
pum = YAML.load_file(POTENTIAL_METHODS_PATH)
pm = pum.flat_map { |f, ml| [f].product(ml) }

umc = unused_method_collection.flat_map { |f, ml| [f].product(ml) }

# Find the difference between each array of method names
#
new_unused_methods = umc - pm
removed_methods = pm - umc

###########################################################
# Report methods that appear unused that we didn't previously record in
#   POTENTIAL_METHODS_PATH
#
unless new_unused_methods.empty?
  error = <<~UPDATE_UNUSED
  ❌ We have detected #{new_unused_methods.size} newly unused methods.

  Please remove these methods, or if in use, add to #{EXCLUDED_METHODS_PATH}.\n
  UPDATE_UNUSED

  puts Rainbow(error).red.bright

  puts Rainbow(parse_methods_diff(new_unused_methods).to_yaml).red.bright
end

if new_unused_methods.size + removed_methods.size > 0
  puts Rainbow("~" * 80).white.bright
  puts "\n"
end

####################################################################################
# Report methods recorded in POTENTIAL_METHODS_PATH that appear to have been removed
#
unless removed_methods.empty?
  warning = <<~UPDATE_UNUSED
  🏆 It appears you have removed unused methods. Thank you!

  Please update potential_methods_to_remove.yml and remove entries for these methods.\n
  UPDATE_UNUSED

  print Rainbow(warning).yellow.bright

  puts Rainbow(parse_methods_diff(removed_methods).to_yaml).yellow.bright
end

exit 1 unless new_unused_methods.empty? && removed_methods.empty?

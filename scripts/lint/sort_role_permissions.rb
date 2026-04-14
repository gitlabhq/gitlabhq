#!/usr/bin/env ruby

# frozen_string_literal: true

# Sorts arrays in role YAML files alphabetically and enforces consistent formatting.
#
# Usage:
#   scripts/lint/sort_role_permissions.rb           # Check only (exits 1 if unsorted)
#   scripts/lint/sort_role_permissions.rb --fix      # Auto-sort and format in place

require 'yaml'

ROLE_DIR = File.expand_path('../../config/authz/roles/*.yml', __dir__)
FIX_MODE = ARGV.include?('--fix')

def sort_value(value)
  case value
  when Array
    value.sort.uniq
  when Hash
    sort_hash_values(value)
  else
    value
  end
end

def sort_hash_values(hash)
  sorted = {}

  hash.each do |key, value|
    sorted[key] = sort_value(value)
  end

  sorted
end

errors = []

Dir.glob(ROLE_DIR).each do |file|
  content = YAML.safe_load_file(file)
  sorted_content = sort_hash_values(content)

  next File.write(file, sorted_content.to_yaml) if FIX_MODE

  errors << File.basename(file) if sorted_content.to_yaml != content.to_yaml
end

unless errors.empty?
  puts "Roles not sorted: \n#{errors.to_yaml.delete_prefix!("---\n")}"
  exit 1
end

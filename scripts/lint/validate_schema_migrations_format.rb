#!/usr/bin/env ruby
# frozen_string_literal: true

# Validates that schema_migrations files don't have trailing newlines.
# Rails' touch_all writes these files without newlines, so committing
# files with newlines will cause db:check-migrations to fail in CI.

require 'digest'

SCHEMA_MIGRATIONS_DIR = 'db/schema_migrations'
VERSION_PATTERN = /\A20\d{12}\z/

def main
  staged_files = `git diff --name-only --cached -- #{SCHEMA_MIGRATIONS_DIR}`.split("\n")
  return 0 if staged_files.empty?

  errors = []

  staged_files.each do |file|
    next unless File.exist?(file)

    basename = File.basename(file)
    next unless basename.match?(VERSION_PATTERN)

    content = File.read(file)

    if content.end_with?("\n")
      errors << {
        file: file,
        issue: "has trailing newline",
        fix: "printf '%s' \"$(cat #{file})\" > #{file}"
      }
    end

    expected_hash = Digest::SHA256.hexdigest(basename)
    actual_hash = content.chomp

    next if actual_hash == expected_hash

    errors << {
      file: file,
      issue: "has incorrect hash (expected #{expected_hash[0..15]}..., got #{actual_hash[0..15]}...)",
      fix: "printf '%s' '#{expected_hash}' > #{file}"
    }
  end

  return 0 if errors.empty?

  puts "\e[31mError: Invalid schema_migrations files detected!\e[0m"
  puts
  puts "The following files will cause db:check-migrations to fail in CI:"
  puts

  errors.each do |error|
    puts "  #{error[:file]}: #{error[:issue]}"
  end

  puts
  puts "\e[33mTo fix, run:\e[0m"
  errors.map { |e| e[:fix] }.uniq.each do |fix|
    puts "  #{fix}"
  end
  puts
  puts "Or fix all at once:"
  puts "  for f in #{staged_files.join(' ')}; do"
  puts "    version=$(basename \"$f\")"
  puts "    printf '%s' \"$(echo -n \"$version\" | sha256sum | cut -d' ' -f1)\" > \"$f\""
  puts "  done"

  1
end

exit main if $PROGRAM_NAME == __FILE__

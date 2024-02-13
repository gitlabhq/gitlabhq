#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../../tooling/lib/tooling/check_ruby_syntax"

files = `git ls-files -z`.split("\0")

checker = Tooling::CheckRubySyntax.new(files)

puts format("Checking %{files} Ruby files...", files: checker.ruby_files.size)

errors = checker.run

puts

if errors.any?
  puts "Syntax errors found (#{errors.size}):"
  puts errors

  exit 1
else
  puts "No syntax errors found."

  exit 0
end

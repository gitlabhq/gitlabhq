#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../setup/gitaly_version_checker'

version_checker = GitalyVersionChecker.new

# Main execution
puts "Checking Gitaly version compatibility..."

gitlab_version = version_checker.parse_gitlab_version(File.read('VERSION'))
gitaly_version = version_checker.parse_gitaly_version(File.read('Gemfile.lock'))

puts "GitLab version: #{gitlab_version}"
puts "Gitaly version: #{gitaly_version}"

if version_checker.version_allowed?(gitlab_version, gitaly_version)
  puts "✅ The Gitaly version used is allowed!"
  puts "   Gitaly (#{gitaly_version}) is at least 1 minor version behind GitLab (#{gitlab_version})"
  exit 0
else
  puts "❌ The Gitaly version used is not allowed!"
  puts "   Gitaly (#{gitaly_version}) must be at least 1 minor version behind GitLab (#{gitlab_version})"
  puts ""
  puts "See documentation: https://docs.gitlab.com/development/gitaly/#gitaly-version-compatibility-requirement"
  exit 1
end

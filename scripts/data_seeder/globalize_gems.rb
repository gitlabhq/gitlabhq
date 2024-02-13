# frozen_string_literal: true

# This script ...
#   - Opens a Gemfile
#   - Copies the line that contains a specific gem and its version
#   - Pastes the copied lines to EOF
#
# ... to pull the gems out of their defined groups (like :development, :test, etc.)
# @note Duplicate entries will be created which will cause Bundler warnings, but this is expected.
# @usage ruby globalize_gems.rb

GEMS_TO_FIND = %w[factory_bot_rails ffaker parallel].freeze

File.open('Gemfile', 'a+') do |file|
  lines_added = []

  file.each_line do |line|
    next unless line.match?(/gem ['"]#{Regexp.union(GEMS_TO_FIND)}["']/)

    lines_added << line
    puts line
  end

  lines_added.each { |ln| file.write(ln) }
end

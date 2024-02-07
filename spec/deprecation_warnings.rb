# frozen_string_literal: true

require 'gitlab/utils/all'
return if Gitlab::Utils.to_boolean(ENV['SILENCE_DEPRECATIONS'], default: false)

# Enable deprecation warnings by default and make them more visible
# to developers to ease upgrading to newer Ruby versions.
Warning[:deprecated] = true

# rubocop:disable Layout/LineLength -- Avoid multiline (x modifier) Regexp to keep it readable
case RUBY_VERSION[/\d+\.\d+/, 0]
when '3.1'
  require 'warning'
  # These warnings only happen in Ruby 3.1 and are gone in Ruby 3.2.
  #  ... ruby/3.1.3/lib/ruby/gems/3.1.0/gems/rspec-parameterized-table_syntax-1.0.0/lib/rspec/parameterized/table_syntax.rb:38: warning: Refinement#include is deprecated and will be removed in Ruby 3.2

  Warning.ignore(%r{rspec-parameterized-table_syntax-1\.0\.0/lib/rspec/parameterized/table_syntax\.rb:\d+: warning: Refinement#include is deprecated})
end
# rubocop:enable Layout/LineLength

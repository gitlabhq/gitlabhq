# frozen_string_literal: true

require_relative '../lib/gitlab/utils'
return if Gitlab::Utils.to_boolean(ENV['SILENCE_DEPRECATIONS'], default: false)

# Enable deprecation warnings by default and make them more visible
# to developers to ease upgrading to newer Ruby versions.
Warning[:deprecated] = true

# rubocop:disable Layout/LineLength
case RUBY_VERSION[/\d+\.\d+/, 0]
when '3.2'
  warn "#{__FILE__}:#{__LINE__}: warning: Ignored warnings for Ruby < 3.2 are no longer necessary."
else
  require 'warning'
  # Ignore Ruby warnings until Ruby 3.2.
  #  ... ruby/3.1.3/lib/ruby/gems/3.1.0/gems/rspec-parameterized-table_syntax-1.0.0/lib/rspec/parameterized/table_syntax.rb:38: warning: Refinement#include is deprecated and will be removed in Ruby 3.2

  Warning.ignore(%r{rspec-parameterized-table_syntax-1\.0\.0/lib/rspec/parameterized/table_syntax\.rb:\d+: warning: Refinement#include is deprecated})
end
# rubocop:enable Layout/LineLength

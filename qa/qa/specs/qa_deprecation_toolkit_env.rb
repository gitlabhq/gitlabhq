# frozen_string_literal: true

require 'deprecation_toolkit'
require 'deprecation_toolkit/rspec'
require 'concurrent/utility/monotonic_time'
require 'active_support/gem_version'

module QA
  module Specs
    class QaDeprecationToolkitEnv
      # Taken from https://github.com/jeremyevans/ruby-warning/blob/1.1.0/lib/warning.rb#L18
      # rubocop:disable Layout/LineLength
      def self.kwargs_warning
        %r{warning: (?:Using the last argument (?:for `.+' )?as keyword parameters is deprecated; maybe \*\* should be added to the call|Passing the keyword argument (?:for `.+' )?as the last hash parameter is deprecated|Splitting the last argument (?:for `.+' )?into positional and keyword parameters is deprecated|The called method (?:`.+' )?is defined here)\n\z}
      end
      # rubocop:enable Layout/LineLength

      def self.configure!
        # Enable ruby deprecations for keywords, it's suppressed by default in Ruby 2.7
        Warning[:deprecated] = true

        DeprecationToolkit::Configuration.test_runner = :rspec
        DeprecationToolkit::Configuration.deprecation_path = 'deprecations'
        DeprecationToolkit::Configuration.warnings_treated_as_deprecation = [kwargs_warning]
      end
    end
  end
end

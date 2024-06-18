# frozen_string_literal: true

require 'deprecation_toolkit'
require 'deprecation_toolkit/rspec'

module DeprecationToolkitEnv
  module DeprecationBehaviors
    class SelectiveRaise
      attr_reader :disallowed_deprecations_proc

      class RaiseDisallowedDeprecation < StandardError
        def initialize(test, current_deprecations)
          message = <<~EOF
            Disallowed deprecations detected while running test #{test}:

            #{current_deprecations.deprecations.join("\n")}
          EOF

          super(message)
        end
      end

      def initialize(disallowed_deprecations_proc)
        @disallowed_deprecations_proc = disallowed_deprecations_proc
      end

      # Note: trigger does not get called if the current_deprecations matches recorded_deprecations
      # See https://github.com/Shopify/deprecation_toolkit/blob/2398f38acb62220fb79a6cd720f61d9cea26bc06/lib/deprecation_toolkit/test_triggerer.rb#L8-L11
      def trigger(test, current_deprecations, recorded_deprecations)
        if selected_for_raise?(current_deprecations)
          raise RaiseDisallowedDeprecation.new(test, current_deprecations)
        elsif ENV['RECORD_DEPRECATIONS']
          record(test, current_deprecations, recorded_deprecations)
        end
      end

      private

      def selected_for_raise?(current_deprecations)
        disallowed_deprecations_proc.call(current_deprecations.deprecations_without_stacktrace)
      end

      def record(test, current_deprecations, recorded_deprecations)
        ::DeprecationToolkit::Behaviors::Record.trigger(test, current_deprecations, recorded_deprecations)
      end
    end
  end

  # Taken from https://github.com/jeremyevans/ruby-warning/blob/1.1.0/lib/warning.rb#L18
  # Note: When a spec fails due to this warning, please update the spec to address the deprecation.
  def self.kwargs_warning
    %r{warning: (?:Using the last argument (?:for `.+' )?as keyword parameters is deprecated; maybe \*\* should be added to the call|Passing the keyword argument (?:for `.+' )?as the last hash parameter is deprecated|Splitting the last argument (?:for `.+' )?into positional and keyword parameters is deprecated|The called method (?:`.+' )?is defined here)\n\z}
  end

  # Note: No new exceptions should be added here, unless they are in external dependencies.
  # In this case, we recommend to add a silence together with an issue to patch or update
  # the dependency causing the problem.
  # See https://gitlab.com/gitlab-org/gitlab/-/commit/aea37f506bbe036378998916d374966c031bf347#note_647515736
  def self.allowed_kwarg_warning_paths
    %w[]
  end

  def self.configure!
    # Enable ruby deprecations for keywords, it's suppressed by default in Ruby 2.7
    Warning[:deprecated] = true

    DeprecationToolkit::Configuration.test_runner = :rspec
    DeprecationToolkit::Configuration.deprecation_path = 'deprecations'
    DeprecationToolkit::Configuration.warnings_treated_as_deprecation = [kwargs_warning]

    disallowed_deprecations = ->(deprecations) do
      deprecations.any? do |deprecation|
        kwargs_warning.match?(deprecation) &&
          allowed_kwarg_warning_paths.none? { |path| deprecation.include?(path) }
      end
    end

    DeprecationToolkit::Configuration.behavior = DeprecationBehaviors::SelectiveRaise.new(disallowed_deprecations)
  end
end

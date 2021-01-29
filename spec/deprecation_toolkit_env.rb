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
  def self.kwargs_warning
    %r{warning: (?:Using the last argument (?:for `.+' )?as keyword parameters is deprecated; maybe \*\* should be added to the call|Passing the keyword argument (?:for `.+' )?as the last hash parameter is deprecated|Splitting the last argument (?:for `.+' )?into positional and keyword parameters is deprecated|The called method (?:`.+' )?is defined here)\n\z}
  end

  # Allow these Gem paths to trigger keyword warnings as we upgrade these gems
  # one by one
  def self.allowed_kwarg_warning_paths
    %w[
      ee/lib/ee/gitlab/usage_data.rb
      spec/lib/gitlab/utils/usage_data_spec.rb
      spec/support/gitlab_experiment.rb
      spec/support/helpers/next_instance_of.rb
      rspec-mocks-3.10.0/lib/rspec/mocks/message_expectation.rb
      activerecord-6.0.3.4/lib/active_record/migration.rb
      devise-4.7.3/lib/devise/test/controller_helpers.rb
      attr_encrypted-3.1.0/lib/attr_encrypted/adapters/active_record.rb
      rspec-mocks-3.10.0/lib/rspec/mocks/message_expectation.rb
      rspec-expectations-3.10.0/lib/rspec/matchers/built_in/has.rb
      grape-1.5.1/lib/grape/middleware/stack.rb
      grape-1.5.1/lib/grape/validations/validators/coerce.rb
      grape_logging-1.8.3/lib/grape_logging/middleware/request_logger.rb
      activesupport-6.0.3.4/lib/active_support/cache.rb
      factory_bot-6.1.0/lib/factory_bot/decorator.rb
      doorkeeper-5.4.0/lib/doorkeeper/models/access_token_mixin.rb
      rouge-3.26.0/lib/rouge/formatter.rb
      batch-loader-1.4.0/lib/batch_loader/graphql.rb
      carrierwave-1.3.1/lib/carrierwave/sanitized_file.rb
      activerecord-6.0.3.4/lib/active_record/relation.rb
    ]
  end

  def self.configure!
    # Enable ruby deprecations for keywords, it's suppressed by default in Ruby 2.7.2
    Warning[:deprecated] = true

    DeprecationToolkit::Configuration.test_runner = :rspec
    DeprecationToolkit::Configuration.deprecation_path = 'deprecations'
    DeprecationToolkit::Configuration.warnings_treated_as_deprecation = [kwargs_warning]

    disallowed_deprecations = -> (deprecations) do
      deprecations.any? do |deprecation|
        kwargs_warning.match?(deprecation) &&
          allowed_kwarg_warning_paths.none? { |path| deprecation.include?(path) }
      end
    end

    DeprecationToolkit::Configuration.behavior = DeprecationBehaviors::SelectiveRaise.new(disallowed_deprecations)
  end
end

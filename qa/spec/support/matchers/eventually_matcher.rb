# frozen_string_literal: true

# Rspec matcher with build in retry logic
#
# USAGE:
#
# Basic
# expect { Something.that.takes.time.to_appear }.to eventually_eq(expected_result)
# expect { Something.that.takes.time.to_appear }.not_to eventually_eq(expected_result)
#
# With duration and attempts override
# expect { Something.that.takes.time.to_appear }.to eventually_eq(expected_result).within(duration: 10, attempts: 5)

module Matchers
  %w[
    eq
    be
    include
    be_truthy
    be_falsey
    be_empty
  ].each do |op|
    RSpec::Matchers.define(:"eventually_#{op}") do |*expected|
      chain(:within) do |options = {}|
        @duration = options[:duration]
        @attempts = options[:attempts]
      end

      def supports_block_expectations?
        true
      end

      match { |actual| wait_and_check(actual, :default_expectation) }

      match_when_negated { |actual| wait_and_check(actual, :when_negated_expectation) }

      description do
        "eventually #{operator_msg} #{expected.inspect}"
      end

      failure_message do
        "#{e}:\nexpected to #{description}, last attempt was #{@result.nil? ? 'nil' : @result}"
      end

      failure_message_when_negated do
        "#{e}:\nexpected not to #{description}, last attempt was #{@result.nil? ? 'nil' : @result}"
      end

      # Execute rspec expectation within retrier
      #
      # @param [Proc] actual
      # @param [Symbol] expectation_name
      # @return [Boolean]
      def wait_and_check(actual, expectation_name)
        QA::Support::Retrier.retry_until(
          max_attempts: @attempts,
          max_duration: @duration,
          sleep_interval: 0.5
        ) do
          public_send(expectation_name, actual)
        rescue RSpec::Expectations::ExpectationNotMetError, QA::Resource::ApiFabricator::ResourceNotFoundError
          false
        end
      rescue QA::Support::Repeater::RetriesExceededError, QA::Support::Repeater::WaitExceededError => e
        @e = e
        false
      end

      # Execute rspec expectation
      #
      # @param [Proc] actual
      # @return [void]
      def default_expectation(actual)
        expect(result(&actual)).to public_send(*expectation_args)
      end

      # Execute negated rspec expectation
      #
      # @param [Proc] actual
      # @return [void]
      def when_negated_expectation(actual)
        expect(result(&actual)).not_to public_send(*expectation_args)
      end

      # Result of actual block
      #
      # @return [Object]
      def result
        @result = yield
      end

      # Error message placeholder to indicate waiter did not fail properly
      # This message should not appear under normal circumstances since it should
      # always be assigned from repeater
      #
      # @return [String]
      def e
        @e ||= 'Waiter did not fail!'
      end

      # Operator message
      #
      # @return [String]
      def operator_msg
        case operator
        when 'eq' then 'equal'
        else operator
        end
      end

      # Expect operator
      #
      # @return [String]
      def operator
        @operator ||= name.to_s.match(/eventually_(.+?)$/).to_a[1].to_s
      end

      # Expectation args
      #
      # @return [String, Array]
      def expectation_args
        if operator.include?('truthy') || operator.include?('falsey') || operator.include?('empty')
          operator
        elsif operator == "include" && expected.is_a?(Array)
          [operator, *expected]
        else
          [operator, expected]
        end
      end
    end
  end
end

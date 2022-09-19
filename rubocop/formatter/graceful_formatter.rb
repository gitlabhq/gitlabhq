# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Formatter
    class GracefulFormatter < ::RuboCop::Formatter::ProgressFormatter
      CONFIG_DETAILS_KEY = 'Details'
      CONFIG_DETAILS_VALUE = 'grace period'

      class << self
        attr_accessor :active_offenses
      end

      def started(...)
        super

        self.class.active_offenses = 0

        @silenced_offenses_for_files = {}
        @config = RuboCop::ConfigStore.new.for_pwd
      end

      def file_finished(file, offenses)
        silenced_offenses, active_offenses = offenses.partition { silenced?(_1) }

        @silenced_offenses_for_files[file] = silenced_offenses if silenced_offenses.any?

        super(file, active_offenses)
      end

      def finished(inspected_files)
        # See the note below why are using this ivar in the first place.
        unless defined?(@total_offense_count)
          raise <<~MESSAGE
            RuboCop has changed its internals and the instance variable
            `@total_offense_count` is no longer defined but we were relying on it.

            Please change the implementation.

            See https://github.com/rubocop/rubocop/blob/65a757b0f/lib/rubocop/formatter/simple_text_formatter.rb#L24
          MESSAGE
        end

        super

        # Internally, RuboCop has no notion of "silenced offenses". We cannot
        # override this meaning in a formatter that's why we track what we
        # consider to be an active offense.
        # This is needed for `adjusted_exit_status` method below.
        self.class.active_offenses = @total_offense_count

        report_silenced_offenses(inspected_files)
      end

      # We consider this run a success without any active offenses.
      def self.adjusted_exit_status(status)
        return status unless status == RuboCop::CLI::STATUS_OFFENSES
        return RuboCop::CLI::STATUS_SUCCESS if active_offenses == 0

        status
      end

      def self.grace_period?(cop_name, config)
        details = config[CONFIG_DETAILS_KEY]
        return false unless details
        return true if details == CONFIG_DETAILS_VALUE

        warn "#{cop_name}: Unhandled value #{details.inspect} for `Details` key."

        false
      end

      def self.grace_period_key_value
        "#{CONFIG_DETAILS_KEY}: #{CONFIG_DETAILS_VALUE}"
      end

      private

      def silenced?(offense)
        cop_config = @config.for_cop(offense.cop_name)

        self.class.grace_period?(offense.cop_name, cop_config)
      end

      def report_silenced_offenses(inspected_files)
        return if @silenced_offenses_for_files.empty?

        output.puts
        output.puts 'Silenced offenses:'
        output.puts

        @silenced_offenses_for_files.each do |file, offenses|
          report_file(file, offenses)
        end

        silenced_offense_count = @silenced_offenses_for_files.values.sum(&:size)
        silenced_text = colorize("#{silenced_offense_count} offenses", :yellow)

        output.puts
        output.puts "#{inspected_files.size} files inspected, #{silenced_text} silenced"
      end

      def report_file_as_mark(_offenses)
        # Skip progress bar. No dots. No C/Ws.
      end
    end
  end
end

# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara-screenshot/rspec'

module QA
  module Runtime
    ##
    # Class that is responsible for plugging CE/EE extensions in, depending on
    # existence of EE module.
    #
    # We need that to reduce the probability of conflicts when merging
    # CE to EE.
    #
    class Release
      def version
        @version ||= ::File.directory?("#{__dir__}/../ee") ? :EE : :CE
      end

      def strategy
        Object.const_get("QA::#{version}::Strategy", false)
      end

      def self.method_missing(name, *args)
        self.new.strategy.public_send(name, *args)
      rescue StandardError
        saved = Capybara::Screenshot.screenshot_and_save_page

        QA::Runtime::Logger.error("Screenshot: #{saved[:image]}") if saved&.key?(:image)
        QA::Runtime::Logger.error("HTML capture: #{saved[:html]}") if saved&.key?(:html)

        raise
      end
    end
  end
end

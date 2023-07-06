# frozen_string_literal: true

require 'active_support/all'
require 'active_support/testing/time_helpers'

module Gitlab
  module Rspec
    module Configurations
      class TimeTravel
        def self.configure!
          RSpec.configure do |config|
            config.include ActiveSupport::Testing::TimeHelpers

            config.around(:example, :freeze_time) do |example|
              freeze_time { example.run }
            end

            config.around(:example, :time_travel_to) do |example|
              date_or_time = example.metadata[:time_travel_to]

              unless date_or_time.respond_to?(:to_time) && date_or_time.to_time.present?
                raise 'The time_travel_to RSpec metadata must have a Date or Time value.'
              end

              travel_to(date_or_time) { example.run }
            end
          end
        end
      end
    end
  end
end

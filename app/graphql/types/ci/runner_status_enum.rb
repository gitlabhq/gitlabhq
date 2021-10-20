# frozen_string_literal: true

module Types
  module Ci
    class RunnerStatusEnum < BaseEnum
      graphql_name 'CiRunnerStatus'

      ::Ci::Runner::AVAILABLE_STATUSES.each do |status|
        description = case status
                      when 'active'
                        "A runner that is not paused."
                      when 'online'
                        "A runner that contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}."
                      when 'offline'
                        "A runner that has not contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}."
                      when 'not_connected'
                        "A runner that has never contacted this instance."
                      else
                        "A runner that is #{status.to_s.tr('_', ' ')}."
                      end

        value status.to_s.upcase,
              description: description,
              value: status.to_sym
      end
    end
  end
end

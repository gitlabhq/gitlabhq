# frozen_string_literal: true

module Types
  module Ci
    class RunnerStatusEnum < BaseEnum
      graphql_name 'CiRunnerStatus'

      value 'ONLINE',
        description: "Runner that contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}.",
        value: :online

      value 'OFFLINE',
        description: "Runner that has not contacted this instance within the " \
          "last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}. Will be considered `STALE` if offline for " \
          "more than #{::Ci::Runner::STALE_TIMEOUT.inspect}.",
        value: :offline

      value 'STALE',
        description: "Runner that has not contacted this instance within the last #{::Ci::Runner::STALE_TIMEOUT.inspect}.",
        value: :stale

      value 'NEVER_CONTACTED',
        description: 'Runner that has never contacted the instance.',
        value: :never_contacted
    end
  end
end

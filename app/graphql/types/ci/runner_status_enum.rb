# frozen_string_literal: true

module Types
  module Ci
    class RunnerStatusEnum < BaseEnum
      graphql_name 'CiRunnerStatus'

      value 'ACTIVE',
            description: 'Runner that is not paused.',
            deprecated: { reason: 'Use CiRunnerType.active instead', milestone: '14.6' },
            value: :active

      value 'PAUSED',
            description: 'Runner that is paused.',
            deprecated: { reason: 'Use CiRunnerType.active instead', milestone: '14.6' },
            value: :paused

      value 'ONLINE',
            description: "Runner that contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}.",
            value: :online

      value 'OFFLINE',
            description: "Runner that has not contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}.",
            deprecated: { reason: 'This field will have a slightly different scope starting in 15.0, with STALE being returned after a certain period offline', milestone: '14.6' },
            value: :offline

      value 'STALE',
            description: "Runner that has not contacted this instance within the last #{::Ci::Runner::STALE_TIMEOUT.inspect}. Only available if legacyMode is null. Will be a possible return value starting in 15.0",
            value: :stale

      value 'NOT_CONNECTED',
            description: 'Runner that has never contacted this instance.',
            deprecated: { reason: 'This field will have a slightly different scope starting in 15.0, with STALE being returned after a certain period of no contact', milestone: '14.6' },
            value: :not_connected
    end
  end
end

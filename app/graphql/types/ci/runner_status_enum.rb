# frozen_string_literal: true

module Types
  module Ci
    class RunnerStatusEnum < BaseEnum
      graphql_name 'CiRunnerStatus'

      value 'ACTIVE',
            description: 'Runner that is not paused.',
            deprecated: {
              reason: :renamed,
              replacement: 'CiRunner.paused',
              milestone: '14.6'
            },
            value: :active

      value 'PAUSED',
            description: 'Runner that is paused.',
            deprecated: {
              reason: :renamed,
              replacement: 'CiRunner.paused',
              milestone: '14.6'
            },
            value: :paused

      value 'ONLINE',
            description: "Runner that contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}.",
            value: :online

      value 'OFFLINE',
            description: "Runner that has not contacted this instance within the last #{::Ci::Runner::ONLINE_CONTACT_TIMEOUT.inspect}.",
            deprecated: { reason: 'This field will have a slightly different scope starting in 15.0, with STALE being returned after a certain period offline', milestone: '14.6' },
            value: :offline

      value 'STALE',
            description: "Runner that has not contacted this instance within the last #{::Ci::Runner::STALE_TIMEOUT.inspect}. Only available if legacyMode is null. Will be a possible return value starting in 15.0.",
            value: :stale

      value 'NOT_CONNECTED',
            description: 'Runner that has never contacted this instance.',
            deprecated: { reason: "Use NEVER_CONTACTED instead. NEVER_CONTACTED will have a slightly different scope starting in 15.0, with STALE being returned instead after #{::Ci::Runner::STALE_TIMEOUT.inspect} of no contact", milestone: '14.6' },
            value: :not_connected

      value 'NEVER_CONTACTED',
            description: 'Runner that has never contacted this instance. Set legacyMode to null to utilize this value. Will replace NOT_CONNECTED starting in 15.0.',
            value: :never_contacted
    end
  end
end

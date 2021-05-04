# frozen_string_literal: true

module Types
  module Ci
    class RunnerStatusEnum < BaseEnum
      graphql_name 'CiRunnerStatus'

      ::Ci::Runner::AVAILABLE_STATUSES.each do |status|
        value status.to_s.upcase,
              description: "A runner that is #{status.to_s.tr('_', ' ')}.",
              value: status.to_sym
      end
    end
  end
end

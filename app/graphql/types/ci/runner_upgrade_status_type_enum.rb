# frozen_string_literal: true

module Types
  module Ci
    class RunnerUpgradeStatusTypeEnum < BaseEnum
      graphql_name 'CiRunnerUpgradeStatusType'

      value 'UNKNOWN', description: 'Upgrade status is unknown.', value: :unknown

      Gitlab::Ci::RunnerUpgradeCheck::STATUSES.each do |status, description|
        value status.to_s.upcase, description: description, value: status
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module Ci
    class RunnerUpgradeStatusTypeEnum < BaseEnum
      graphql_name 'CiRunnerUpgradeStatusType'

      ::Ci::RunnerVersion::STATUS_DESCRIPTIONS.each do |status, description|
        status = :invalid if status == :invalid_version

        value status.to_s.upcase, description: description, value: status
      end
    end
  end
end

# frozen_string_literal: true

module Types
  module Ci
    class RunnerUpgradeStatusTypeEnum < BaseEnum
      graphql_name 'CiRunnerUpgradeStatusType'

      value 'NOT_AVAILABLE',
            description: "An update is not available for the runner.",
            value: :not_available

      value 'AVAILABLE',
            description: "An update is available for the runner.",
            value: :available

      value 'RECOMMENDED',
            description: "An update is available and recommended for the runner.",
            value: :recommended
    end
  end
end

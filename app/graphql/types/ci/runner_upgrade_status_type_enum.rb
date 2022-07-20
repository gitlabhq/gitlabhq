# frozen_string_literal: true

module Types
  module Ci
    class RunnerUpgradeStatusTypeEnum < BaseEnum
      graphql_name 'CiRunnerUpgradeStatusType'

      ::Ci::RunnerVersion::STATUS_DESCRIPTIONS.each do |status, description|
        status_name_src =
          if status == :invalid_version
            :invalid
          else
            status
          end

        value status_name_src.to_s.upcase, description: description, value: status
      end
    end
  end
end

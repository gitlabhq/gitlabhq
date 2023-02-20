# frozen_string_literal: true

module Types
  module Ci
    class RunnerUpgradeStatusEnum < BaseEnum
      graphql_name 'CiRunnerUpgradeStatus'

      MODEL_STATUS_TO_GRAPHQL_TRANSLATIONS = {
        invalid_version: :invalid,
        unavailable: :not_available
      }.freeze

      ::Ci::RunnerVersion::STATUS_DESCRIPTIONS.each do |status, description|
        status_name_src = MODEL_STATUS_TO_GRAPHQL_TRANSLATIONS.fetch(status, status)

        value status_name_src.to_s.upcase, description: description, value: status
      end
    end
  end
end

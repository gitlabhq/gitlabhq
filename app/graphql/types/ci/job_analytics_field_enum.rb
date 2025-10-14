# frozen_string_literal: true

module Types
  module Ci
    class JobAnalyticsFieldEnum < BaseEnum
      graphql_name 'CiJobAnalyticsField'
      description 'Fields available for selection in CI/CD job analytics'

      value 'NAME', value: :name, description: 'Job name.'
      value 'STAGE', value: :stage_id, description: 'Stage.'
    end
  end
end

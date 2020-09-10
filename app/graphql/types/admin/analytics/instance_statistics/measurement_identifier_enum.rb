# frozen_string_literal: true

module Types
  module Admin
    module Analytics
      module InstanceStatistics
        class MeasurementIdentifierEnum < BaseEnum
          graphql_name 'MeasurementIdentifier'
          description 'Possible identifier types for a measurement'

          value 'PROJECTS', 'Project count', value: :projects
          value 'USERS', 'User count', value: :users
          value 'ISSUES', 'Issue count', value: :issues
          value 'MERGE_REQUESTS', 'Merge request count', value: :merge_requests
          value 'GROUPS', 'Group count', value: :groups
          value 'PIPELINES', 'Pipeline count', value: :pipelines
        end
      end
    end
  end
end

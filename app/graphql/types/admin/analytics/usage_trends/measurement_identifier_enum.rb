# frozen_string_literal: true

module Types
  module Admin
    module Analytics
      module UsageTrends
        class MeasurementIdentifierEnum < BaseEnum
          graphql_name 'MeasurementIdentifier'
          description 'Possible identifier types for a measurement'

          value 'PROJECTS', 'Project count.', value: 'projects'
          value 'USERS', 'User count.', value: 'users'
          value 'ISSUES', 'Issue count.', value: 'issues'
          value 'MERGE_REQUESTS', 'Merge request count.', value: 'merge_requests'
          value 'GROUPS', 'Group count.', value: 'groups'
          value 'PIPELINES', 'Pipeline count.', value: 'pipelines'
          value 'PIPELINES_SUCCEEDED', 'Pipeline count with success status.', value: 'pipelines_succeeded'
          value 'PIPELINES_FAILED', 'Pipeline count with failed status.', value: 'pipelines_failed'
          value 'PIPELINES_CANCELED', 'Pipeline count with canceled status.', value: 'pipelines_canceled'
          value 'PIPELINES_SKIPPED', 'Pipeline count with skipped status.', value: 'pipelines_skipped'
        end
      end
    end
  end
end

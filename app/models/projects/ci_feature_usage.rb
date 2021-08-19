# frozen_string_literal: true

module Projects
  class CiFeatureUsage < ApplicationRecord
    self.table_name = 'project_ci_feature_usages'

    belongs_to :project

    validates :project, :feature, presence: true

    enum feature: {
      code_coverage: 1,
      security_report: 2
    }

    def self.insert_usage(project_id:, feature:, default_branch:)
      insert(
        {
          project_id: project_id,
          feature: feature,
          default_branch: default_branch
        },
        unique_by: 'index_project_ci_feature_usages_unique_columns'
      )
    end
  end
end

# frozen_string_literal: true

module Users
  class ProjectCallout < ApplicationRecord
    include Users::Calloutable

    self.table_name = 'user_project_callouts'

    belongs_to :project

    enum feature_name: {
      awaiting_members_banner: 1, # EE-only
      web_hook_disabled: 2,
      ultimate_feature_removal_banner: 3
    }

    validates :project, presence: true
    validates :feature_name,
              presence: true,
              uniqueness: { scope: [:user_id, :project_id] },
              inclusion: { in: ProjectCallout.feature_names.keys }
  end
end

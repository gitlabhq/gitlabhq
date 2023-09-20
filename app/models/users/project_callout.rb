# frozen_string_literal: true

module Users
  class ProjectCallout < ApplicationRecord
    include Users::Calloutable

    self.table_name = 'user_project_callouts'

    belongs_to :project

    enum feature_name: {
      awaiting_members_banner: 1, # EE-only
      web_hook_disabled: 2,
      # 3 was removed https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129703,
      # and cleaned up https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129924, it can be replaced
      namespace_storage_pre_enforcement_banner: 4, # EE-only
      # 5,6,7 were removed https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118330, they can be replaced
      license_check_deprecation_alert: 8 # EE-only
    }

    validates :project, presence: true
    validates :feature_name,
      presence: true,
      uniqueness: { scope: [:user_id, :project_id] },
      inclusion: { in: ProjectCallout.feature_names.keys }
  end
end

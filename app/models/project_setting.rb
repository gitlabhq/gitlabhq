# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  belongs_to :project, inverse_of: :project_setting

  self.primary_key = :project_id
end

ProjectSetting.prepend_if_ee('EE::ProjectSetting')

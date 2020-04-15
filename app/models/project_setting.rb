# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  belongs_to :project, inverse_of: :project_setting

  self.primary_key = :project_id

  def self.where_or_create_by(attrs)
    where(primary_key => safe_find_or_create_by(attrs))
  end
end

ProjectSetting.prepend_if_ee('EE::ProjectSetting')

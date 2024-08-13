# frozen_string_literal: true

class LfsFileLock < ApplicationRecord
  belongs_to :project
  belongs_to :user

  scope :for_paths, ->(paths) { where(path: paths) }
  scope :not_for_users, ->(user_ids) { where.not(user_id: user_ids) }

  validates :project_id, :user_id, :path, presence: true

  def can_be_unlocked_by?(current_user, forced = false)
    return true if current_user.id == user_id

    forced && current_user.can?(:admin_project, project)
  end
end

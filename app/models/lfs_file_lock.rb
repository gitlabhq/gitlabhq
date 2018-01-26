class LfsFileLock < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  validates :project_id, :user_id, :path, presence: true

  def can_be_unlocked_by?(current_user, forced = false)
    return true if current_user.id == user_id

    forced && current_user.can?(:admin_project, project)
  end
end

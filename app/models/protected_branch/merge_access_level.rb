class ProtectedBranch::MergeAccessLevel < ActiveRecord::Base
  belongs_to :protected_branch
  delegate :project, to: :protected_branch

  enum access_level: [:masters, :developers]

  def check_access(user)
    if masters?
      user.can?(:push_code, project) if project.team.master?(user)
    elsif developers?
      user.can?(:push_code, project) if project.team.master?(user) || project.team.developer?(user)
    end
  end
end

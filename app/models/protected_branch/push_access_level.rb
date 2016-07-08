class ProtectedBranch::PushAccessLevel < ActiveRecord::Base
  belongs_to :protected_branch
  delegate :project, to: :protected_branch

  enum access_level: [:masters, :developers, :no_one]

  def check_access(user)
    if masters?
      user.can?(:push_code, project) if project.team.master?(user)
    elsif developers?
      user.can?(:push_code, project) if (project.team.master?(user) || project.team.developer?(user))
    elsif no_one?
      false
    end
  end
end

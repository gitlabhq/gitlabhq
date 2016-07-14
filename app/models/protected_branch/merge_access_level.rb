class ProtectedBranch::MergeAccessLevel < ActiveRecord::Base
  belongs_to :protected_branch
  delegate :project, to: :protected_branch

  enum access_level: [:masters, :developers]

  def self.human_access_levels
    {
      "masters" => "Masters",
      "developers" => "Developers + Masters"
    }.with_indifferent_access
  end

  def check_access(user)
    if masters?
      user.can?(:push_code, project) if project.team.master?(user)
    elsif developers?
      user.can?(:push_code, project) if project.team.master?(user) || project.team.developer?(user)
    end
  end

  def humanize
    self.class.human_access_levels[self.access_level]
  end
end

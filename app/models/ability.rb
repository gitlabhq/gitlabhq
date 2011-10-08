class Ability
  def self.allowed(object, subject)
    case subject.class.name
    when "Project" then project_abilities(object, subject)
    else []
    end
  end

  def self.project_abilities(user, project)
    rules = []

    rules << [
      :read_project,
      :read_issue,
      :read_team_member,
      :read_note 
    ] if project.readers.include?(user)

    rules << [
      :write_project,
      :write_issue,
      :write_note 
    ] if project.writers.include?(user)

    rules << [
      :admin_project,
      :admin_issue,
      :admin_team_member,
      :admin_note 
    ] if project.admins.include?(user)

    rules.flatten
  end
end

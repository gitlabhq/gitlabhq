class Ability
  def self.allowed(object, subject)
    case subject.class.name
    when "Project" then project_abilities(object, subject)
    when "Issue" then issue_abilities(object, subject)
    when "Note" then note_abilities(object, subject)
    when "Snippet" then snippet_abilities(object, subject)
    when "MergeRequest" then merge_request_abilities(object, subject)
    else []
    end
  end

  def self.project_abilities(user, project)
    rules = []

    rules << [
      :read_project,
      :read_wiki,
      :read_issue,
      :read_milestone,
      :read_snippet,
      :read_team_member,
      :read_merge_request,
      :read_note,
      :write_project,
      :write_issue,
      :write_note
    ] if project.guest_access_for?(user)

    rules << [
      :download_code,
      :write_merge_request,
      :write_snippet
    ] if project.report_access_for?(user)

    rules << [
      :write_wiki
    ] if project.dev_access_for?(user)

    rules << [
      :modify_issue,
      :modify_snippet,
      :modify_merge_request,
      :admin_project,
      :admin_issue,
      :admin_milestone,
      :admin_snippet,
      :admin_team_member,
      :admin_merge_request,
      :admin_note,
      :accept_mr,
      :admin_wiki
    ] if project.master_access_for?(user) || project.owner == user

    rules.flatten
  end

  class << self
    [:issue, :note, :snippet, :merge_request].each do |name|
      define_method "#{name}_abilities" do |user, subject|
        if subject.author == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
            :"admin_#{name}"
          ]
        elsif subject.respond_to?(:assignee) && subject.assignee == user
          [
            :"read_#{name}",
            :"write_#{name}",
            :"modify_#{name}",
          ]
        else
          subject.respond_to?(:project) ?
            project_abilities(user, subject.project) : []
        end
      end
    end
  end
end

class MembersFinder
  attr_reader :project, :current_user, :group

  def initialize(project, current_user)
    @project = project
    @current_user = current_user
    @group = project.group
  end

  def execute
    project_members = project.project_members
    project_members = project_members.non_invite unless can?(current_user, :admin_project, project)
    wheres = ["members.id IN (#{project_members.select(:id).to_sql})"]

    if group
      # We need `.where.not(user_id: nil)` here otherwise when a group has an
      # invitee, it would make the following query return 0 rows since a NULL
      # user_id would be present in the subquery
      # See http://stackoverflow.com/questions/129077/not-in-clause-and-null-values
      non_null_user_ids = project_members.where.not(user_id: nil).select(:user_id)

      group_members = GroupMembersFinder.new(group).execute
      group_members = group_members.where.not(user_id: non_null_user_ids)
      group_members = group_members.non_invite unless can?(current_user, :admin_group, group)

      wheres << "members.id IN (#{group_members.select(:id).to_sql})"
    end

    Member.where(wheres.join(' OR '))
  end

  def can?(*args)
    Ability.allowed?(*args)
  end
end

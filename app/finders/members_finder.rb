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

    if group
      group_members = GroupMembersFinder.new(group).execute
      group_members = group_members.non_invite unless can?(current_user, :admin_group, group)

      union = Gitlab::SQL::Union.new([project_members, group_members], remove_duplicates: false)

      # We're interested in a list of members without duplicates by user_id.
      # We prefer project members over group members, project members should go first.
      #
      # We could have used a DISTINCT ON here, but MySQL does not support this.
      sql = <<-SQL
        SELECT member_numbered.*
        FROM (
          SELECT
          member_union.*,
          ROW_NUMBER() OVER (
            PARTITION BY user_id ORDER BY CASE WHEN type = 'ProjectMember' THEN 1 WHEN type = 'GroupMember' THEN 2 ELSE 3 END
          ) AS row_number
          FROM (#{union.to_sql}) AS member_union
       ) AS member_numbered
       WHERE row_number = 1
      SQL

      Member.from("(#{sql}) AS #{Member.table_name}")
    else
      project_members
    end
  end

  def can?(*args)
    Ability.allowed?(*args)
  end
end

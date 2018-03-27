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
      group_members = group_members.non_invite

      union = Gitlab::SQL::Union.new([project_members, group_members], remove_duplicates: false)

      sql = distinct_on(union)

      Member.includes(:user).from("(#{sql}) AS #{Member.table_name}")
    else
      project_members
    end
  end

  def can?(*args)
    Ability.allowed?(*args)
  end

  private

  def distinct_on(union)
    # We're interested in a list of members without duplicates by user_id.
    # We prefer project members over group members, project members should go first.
    if Gitlab::Database.postgresql?
      <<~SQL
          SELECT DISTINCT ON (user_id, invite_email) member_union.*
          FROM (#{union.to_sql}) AS member_union
          ORDER BY user_id,
            invite_email,
            CASE
              WHEN type = 'ProjectMember' THEN 1
              WHEN type = 'GroupMember' THEN 2
              ELSE 3
            END
      SQL
    else
      # Older versions of MySQL do not support window functions (and DISTINCT ON is postgres-specific).
      <<~SQL
          SELECT t1.*
          FROM (#{union.to_sql}) AS t1
          JOIN (
            SELECT
              COALESCE(user_id, -1) AS user_id,
              COALESCE(invite_email, 'NULL') AS invite_email,
              MIN(CASE WHEN type = 'ProjectMember' THEN 1 WHEN type = 'GroupMember' THEN 2 ELSE 3 END) AS type_number
            FROM
            (#{union.to_sql}) AS t3
            GROUP BY COALESCE(user_id, -1), COALESCE(invite_email, 'NULL')
          ) AS t2 ON COALESCE(t1.user_id, -1) = t2.user_id
                 AND COALESCE(t1.invite_email, 'NULL') = t2.invite_email
                 AND CASE WHEN t1.type = 'ProjectMember' THEN 1 WHEN t1.type = 'GroupMember' THEN 2 ELSE 3 END = t2.type_number
      SQL
    end
  end
end

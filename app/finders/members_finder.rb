# frozen_string_literal: true

class MembersFinder
  attr_reader :project, :current_user, :group

  def initialize(project, current_user)
    @project = project
    @current_user = current_user
    @group = project.group
  end

  def execute(include_relations: [:inherited, :direct])
    project_members = project.project_members
    project_members = project_members.non_invite unless can?(current_user, :admin_project, project)

    return project_members if include_relations == [:direct]

    union_members = group_union_members(include_relations)

    union_members << project_members if include_relations.include?(:direct)

    if union_members.any?
      distinct_union_of_members(union_members)
    else
      project_members
    end
  end

  def can?(*args)
    Ability.allowed?(*args)
  end

  private

  def group_union_members(include_relations)
    [].tap do |members|
      members << direct_group_members(include_relations.include?(:descendants)) if group
      members << project_invited_groups_members if include_relations.include?(:invited_groups_members)
    end
  end

  def direct_group_members(include_descendants)
    requested_relations = [:inherited, :direct]
    requested_relations << :descendants if include_descendants
    GroupMembersFinder.new(group).execute(include_relations: requested_relations).non_invite # rubocop: disable CodeReuse/Finder
  end

  def project_invited_groups_members
    invited_groups_ids_including_ancestors = Gitlab::ObjectHierarchy
      .new(project.invited_groups)
      .base_and_ancestors
      .public_or_visible_to_user(current_user)
      .select(:id)

    GroupMember.with_source_id(invited_groups_ids_including_ancestors)
  end

  def distinct_union_of_members(union_members)
    union = Gitlab::SQL::Union.new(union_members, remove_duplicates: false) # rubocop: disable Gitlab/Union
    sql = distinct_on(union)

    Member.includes(:user).from([Arel.sql("(#{sql}) AS #{Member.table_name}")]) # rubocop: disable CodeReuse/ActiveRecord
  end

  def distinct_on(union)
    # We're interested in a list of members without duplicates by user_id.
    # We prefer project members over group members, project members should go first.
    <<~SQL
          SELECT DISTINCT ON (user_id, invite_email) #{member_columns}
          FROM (#{union.to_sql}) AS #{member_union_table}
          LEFT JOIN users on users.id = member_union.user_id
          LEFT JOIN project_authorizations on project_authorizations.user_id = users.id
               AND
               project_authorizations.project_id = #{project.id}
          ORDER BY user_id,
            invite_email,
            CASE
              WHEN type = 'ProjectMember' THEN 1
              WHEN type = 'GroupMember' THEN 2
              ELSE 3
            END
    SQL
  end

  def member_union_table
    'member_union'
  end

  def member_columns
    Member.column_names.map do |column_name|
      # fallback to members.access_level when project_authorizations.access_level is missing
      next "COALESCE(#{ProjectAuthorization.table_name}.access_level, #{member_union_table}.access_level) access_level" if column_name == 'access_level'

      "#{member_union_table}.#{column_name}"
    end.join(',')
  end
end

# frozen_string_literal: true

class MembersFinder
  RELATIONS = %i(direct inherited descendants invited_groups).freeze
  DEFAULT_RELATIONS = %i(direct inherited).freeze

  # Params can be any of the following:
  #   sort:       string
  #   search:     string
  attr_reader :params

  def initialize(project, current_user, params: {})
    @project = project
    @group = project.group
    @current_user = current_user
    @params = params
  end

  def execute(include_relations: DEFAULT_RELATIONS)
    members = find_members(include_relations)

    filter_members(members)
  end

  def can?(*args)
    Ability.allowed?(*args)
  end

  private

  attr_reader :project, :current_user, :group

  def find_members(include_relations)
    project_members = project.project_members

    if params[:active_without_invites_and_requests].present?
      project_members = project_members.active_without_invites_and_requests
    else
      project_members = project_members.non_invite unless can?(current_user, :admin_project, project)
    end

    return project_members if include_relations == [:direct]

    union_members = group_union_members(include_relations)
    union_members << project_members if include_relations.include?(:direct)

    return project_members unless union_members.any?

    distinct_union_of_members(union_members)
  end

  def filter_members(members)
    members = members.search(params[:search]) if params[:search].present?
    members = members.sort_by_attribute(params[:sort]) if params[:sort].present?
    members = members.owners_and_maintainers if params[:owners_and_maintainers].present?
    members
  end

  def group_union_members(include_relations)
    [].tap do |members|
      members << direct_group_members(include_relations.include?(:descendants)) if group
      members << project_invited_groups if include_relations.include?(:invited_groups)
    end
  end

  def direct_group_members(include_descendants)
    requested_relations = [:inherited, :direct]
    requested_relations << :descendants if include_descendants
    GroupMembersFinder.new(group).execute(include_relations: requested_relations).non_invite.non_minimal_access # rubocop: disable CodeReuse/Finder
  end

  def project_invited_groups
    invited_groups_ids_including_ancestors = Gitlab::ObjectHierarchy
      .new(project.invited_groups)
      .base_and_ancestors
      .public_or_visible_to_user(current_user)
      .select(:id)

    GroupMember.with_source_id(invited_groups_ids_including_ancestors).non_minimal_access
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

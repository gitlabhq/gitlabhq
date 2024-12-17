# frozen_string_literal: true

class MembersFinder
  include Members::RoleParser

  RELATIONS = %i[direct inherited descendants invited_groups shared_into_ancestors].freeze
  DEFAULT_RELATIONS = %i[direct inherited].freeze

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

  def can?(...)
    Ability.allowed?(...)
  end

  private

  attr_reader :project, :current_user, :group

  def find_members(include_relations)
    project_members = project.namespace_members

    if params[:active_without_invites_and_requests].present?
      project_members = project_members.active_without_invites_and_requests
    else
      project_members = project_members.non_invite unless can?(current_user, :admin_project, project)
    end

    return project_members if include_relations == [:direct]

    union_members = group_union_members(include_relations)
    union_members << project_members.select(Member.column_names) if include_relations.include?(:direct)

    return project_members unless union_members.any?

    distinct_union_of_members(union_members)
  end

  def filter_members(members)
    members = members.search(params[:search]) if params[:search].present?
    members = members.sort_by_attribute(params[:sort]) if params[:sort].present?
    members = members.owners_and_maintainers if params[:owners_and_maintainers].present?
    filter_by_max_role(members)
  end

  def filter_by_max_role(members)
    max_role = get_access_level(params[:max_role])
    return members unless max_role&.in?(Gitlab::Access.all_values)

    members.all_by_access_level(max_role).with_static_role
  end

  def group_union_members(include_relations)
    [].tap do |members|
      members << direct_group_members(include_relations).select(Member.column_names) if group
      members << project_invited_groups if include_relations.include?(:invited_groups)
    end
  end

  def direct_group_members(include_relations)
    requested_relations = [:inherited, :direct]
    requested_relations << :descendants if include_relations.include?(:descendants)
    requested_relations << :shared_from_groups if include_relations.include?(:shared_into_ancestors)

    GroupMembersFinder.new(group, current_user) # rubocop: disable CodeReuse/Finder
                      .execute(include_relations: requested_relations)
                      .non_invite
                      .non_minimal_access
  end

  def project_invited_groups
    invited_groups_including_ancestors = project.invited_groups.self_and_ancestors
    unless project.member?(current_user)
      invited_groups_including_ancestors = invited_groups_including_ancestors.public_or_visible_to_user(current_user)
    end

    invited_groups_ids_including_ancestors = invited_groups_including_ancestors.select(:id)
    invited_group_members = GroupMember.with_source_id(invited_groups_ids_including_ancestors).non_minimal_access
    return invited_group_members.select(Member.column_names) if project.share_with_group_enabled?

    # Return no access for invited group members when project sharing with group is disabled
    invited_group_members.coerce_to_no_access
  end

  def distinct_union_of_members(union_members)
    union = Gitlab::SQL::Union.new(union_members, remove_duplicates: false) # rubocop: disable Gitlab/Union
    sql = distinct_on(union)

    # enumerate the columns here since we are enumerating them in the union and want to be immune to
    # column caching issues when adding/removing columns
    Member.select(*Member.column_names)
          .preload(:user).from([Arel.sql("(#{sql}) AS #{Member.table_name}")]) # rubocop: disable CodeReuse/ActiveRecord -- TODO: Usage of `from` forces us to use this.
  end

  def distinct_on(union)
    # We're interested in a list of members without duplicates by user_id.
    # We prefer project members over group members, project members should go first.
    <<~SQL
          SELECT DISTINCT ON (user_id, invite_email) #{member_columns}
          FROM (#{union.to_sql}) AS #{member_union_table}
          LEFT JOIN project_authorizations on project_authorizations.user_id = member_union.user_id
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

  def project_authorization_table
    ProjectAuthorization.table_name
  end

  def member_columns
    Member.column_names.map do |column_name|
      # fallback to members.access_level when project_authorizations.access_level is missing
      if column_name == 'access_level'
        next "COALESCE(#{project_authorization_table}.access_level, #{member_union_table}.access_level) access_level"
      end

      "#{member_union_table}.#{column_name}"
    end.join(',')
  end
end

MembersFinder.prepend_mod

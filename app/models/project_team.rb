# frozen_string_literal: true

class ProjectTeam
  attr_accessor :project

  def initialize(project)
    @project = project
  end

  def add_guest(user, current_user: nil)
    add_member(user, :guest, current_user: current_user)
  end

  def add_planner(user, current_user: nil)
    add_member(user, :planner, current_user: current_user)
  end

  def add_reporter(user, current_user: nil)
    add_member(user, :reporter, current_user: current_user)
  end

  def add_developer(user, current_user: nil)
    add_member(user, :developer, current_user: current_user)
  end

  def add_maintainer(user, current_user: nil)
    add_member(user, :maintainer, current_user: current_user)
  end

  def add_owner(user, current_user: nil)
    add_member(user, :owner, current_user: current_user)
  end

  def add_role(user, role, current_user: nil)
    public_send(:"add_#{role}", user, current_user: current_user) # rubocop:disable GitlabSecurity/PublicSend
  end

  def find_member(user_id)
    member = project.members.find_by(user_id: user_id)

    # If user is not in project members
    # we should check for group membership
    if group && !member
      member = group.members.find_by(user_id: user_id)
    end

    member
  end

  def add_members(users, access_level, current_user: nil, expires_at: nil)
    Members::Projects::CreatorService.add_members( # rubocop:disable CodeReuse/ServiceClass
      project,
      users,
      access_level,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_member(user, access_level, current_user: nil, expires_at: nil)
    Members::Projects::CreatorService.add_member( # rubocop:disable CodeReuse/ServiceClass
      project,
      user,
      access_level,
      current_user: current_user,
      expires_at: expires_at)
  end

  # Remove all users from project team
  def truncate
    ProjectMember.truncate_team(project)
  end

  def members
    @members ||= fetch_members
  end
  alias_method :users, :members

  # `members` method uses project_authorizations table which
  # is updated asynchronously, on project move it still contains
  # old members who may not have access to the new location,
  # so we filter out only members of project or project's group
  def members_in_project_and_ancestors
    members.where(id: member_user_ids)
      .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/432606')
  end

  def members_with_access_levels(access_levels = [])
    fetch_members(access_levels)
  end

  def guests
    @guests ||= fetch_members(Gitlab::Access::GUEST)
  end

  def planners
    @planners ||= fetch_members(Gitlab::Access::PLANNER)
  end

  def reporters
    @reporters ||= fetch_members(Gitlab::Access::REPORTER)
  end

  def developers
    @developers ||= fetch_members(Gitlab::Access::DEVELOPER)
  end

  def maintainers
    @maintainers ||= fetch_members(Gitlab::Access::MAINTAINER)
  end

  def owners
    @owners ||=
      if group
        group.owners.allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/432606")
      else
        # workaround until we migrate Project#owners to have membership with
        # OWNER access level
        Array.wrap(fetch_members(Gitlab::Access::OWNER)) | Array.wrap(project.owner)
      end
  end

  def owner?(user)
    owners.include?(user)
  end

  def import(source_project, current_user)
    target_project = project

    source_members = source_members_for_import(source_project)
    target_user_ids = target_project.project_members.pluck_user_ids

    importer_access_level = max_member_access(current_user.id)

    source_members.reject! do |member|
      # Skip if user already present in team
      !member.invite? && target_user_ids.include?(member.user_id)
    end

    source_members.map! do |member|
      new_member = member.dup
      new_member.id = nil
      new_member.source = target_project
      # So that a maintainer cannot import a member with owner access
      new_member.access_level = [new_member.access_level, importer_access_level].min
      new_member.created_by = current_user
      new_member
    end

    ProjectMember.transaction do
      source_members.each(&:save)
    end

    source_members
  rescue StandardError
    false
  end

  def guest?(user)
    max_member_access(user.id) == Gitlab::Access::GUEST
  end

  def planner?(user)
    max_member_access(user.id) == Gitlab::Access::PLANNER
  end

  def reporter?(user)
    max_member_access(user.id) == Gitlab::Access::REPORTER
  end

  def developer?(user)
    max_member_access(user.id) == Gitlab::Access::DEVELOPER
  end

  def maintainer?(user)
    max_member_access(user.id) == Gitlab::Access::MAINTAINER
  end

  # Checks if `user` is authorized for this project, with at least the
  # `min_access_level` (if given).
  def member?(user, min_access_level = Gitlab::Access::GUEST)
    return false unless user

    max_member_access(user.id) >= min_access_level
  end

  # Only for direct and not invited members
  def has_user?(user)
    return false unless user

    project.project_members.non_invite.exists?(user: user)
  end

  def human_max_access(user_id)
    Gitlab::Access.human_access(max_member_access(user_id))
  end

  # Determine the maximum access level for a group of users in bulk.
  #
  # Returns a Hash mapping user ID -> maximum access level.
  def max_member_access_for_user_ids(user_ids)
    Gitlab::SafeRequestLoader.execute(
      resource_key: project.max_member_access_for_resource_key(User),
      resource_ids: user_ids,
      default_value: Gitlab::Access::NO_ACCESS
    ) do |user_ids|
      project.project_authorizations
             .where(user: user_ids)
             .group(:user_id)
             .maximum(:access_level)
    end
  end

  def write_member_access_for_user_id(user_id, project_access_level)
    project.merge_value_to_request_store(User, user_id, project_access_level)
  end

  def purge_member_access_cache_for_user_id(user_id)
    project.purge_resource_id_from_request_store(User, user_id)
  end

  def max_member_access(user_id)
    max_member_access_for_user_ids([user_id])[user_id]
  end

  def contribution_check_for_user_ids(user_ids)
    Gitlab::SafeRequestLoader.execute(
      resource_key: "contribution_check_for_users:#{project.id}",
      resource_ids: user_ids,
      default_value: false
    ) do |user_ids|
      project.merge_requests
             .merged
             .where(author_id: user_ids, target_branch: project.default_branch.to_s)
             .pluck(:author_id)
             .product([true]).to_h
    end
  end

  def contributor?(user_id)
    return false if max_member_access(user_id) >= Gitlab::Access::GUEST

    contribution_check_for_user_ids([user_id])[user_id]
  end

  private

  def fetch_members(level = nil)
    members = project.authorized_users
    members = members.where(project_authorizations: { access_level: level }) if level

    members
  end

  def group
    project.group
  end

  def member_user_ids
    Member.on_project_and_ancestors(project).select(:user_id)
  end

  def source_members_for_import(source_project)
    source_project.project_members.to_a
  end
end

ProjectTeam.prepend_mod_with('ProjectTeam')

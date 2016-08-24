class ProjectTeam
  attr_accessor :project

  def initialize(project)
    @project = project
  end

  # Shortcut to add users
  #
  # Use:
  #   @team << [@user, :master]
  #   @team << [@users, :master]
  #
  def <<(args)
    users, access, current_user = *args

    if users.respond_to?(:each)
      add_users(users, access, current_user: current_user)
    else
      add_user(users, access, current_user: current_user)
    end
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

  def add_users(users, access, current_user: nil, expires_at: nil)
    return false if group_member_lock

    ProjectMember.add_users_to_projects(
      [project.id],
      users,
      access,
      current_user: current_user,
      expires_at: expires_at
    )
  end

  def add_user(user, access, current_user: nil, expires_at: nil)
    add_users([user], access, current_user: current_user, expires_at: expires_at)
  end

  # Remove all users from project team
  def truncate
    ProjectMember.truncate_team(project)
  end

  def members
    @members ||= fetch_members
  end
  alias_method :users, :members

  def guests
    @guests ||= fetch_members(:guests)
  end

  def reporters
    @reporters ||= fetch_members(:reporters)
  end

  def developers
    @developers ||= fetch_members(:developers)
  end

  def masters
    @masters ||= fetch_members(:masters)
  end

  def import(source_project, current_user = nil)
    target_project = project

    source_members = source_project.project_members.to_a
    target_user_ids = target_project.project_members.pluck(:user_id)

    source_members.reject! do |member|
      # Skip if user already present in team
      !member.invite? && target_user_ids.include?(member.user_id)
    end

    source_members.map! do |member|
      new_member = member.dup
      new_member.id = nil
      new_member.source = target_project
      new_member.created_by = current_user
      new_member
    end

    ProjectMember.transaction do
      source_members.each do |member|
        member.save
      end
    end

    true
  rescue
    false
  end

  def guest?(user)
    max_member_access(user.id) == Gitlab::Access::GUEST
  end

  def reporter?(user)
    max_member_access(user.id) == Gitlab::Access::REPORTER
  end

  def developer?(user)
    max_member_access(user.id) == Gitlab::Access::DEVELOPER
  end

  def master?(user)
    max_member_access(user.id) == Gitlab::Access::MASTER
  end

  def member?(user, min_member_access = nil)
    member = !!find_member(user.id)

    if min_member_access
      member && max_member_access(user.id) >= min_member_access
    else
      member
    end
  end

  def human_max_access(user_id)
    Gitlab::Access.options_with_owner.key(max_member_access(user_id))
  end

  # Determine the maximum access level for a group of users in bulk.
  #
  # Returns a Hash mapping user ID -> maximum access level.
  def max_member_access_for_user_ids(user_ids)
    user_ids = user_ids.uniq
    key = "max_member_access:#{project.id}"

    access = {}

    if RequestStore.active?
      RequestStore.store[key] ||= {}
      access = RequestStore.store[key]
    end

    # Lookup only the IDs we need
    user_ids = user_ids - access.keys

    if user_ids.present?
      user_ids.each { |id| access[id] = Gitlab::Access::NO_ACCESS }

      member_access = project.members.access_for_user_ids(user_ids)
      merge_max!(access, member_access)

      if group
        group_access = group.members.access_for_user_ids(user_ids)
        merge_max!(access, group_access)
      end

      # Each group produces a list of maximum access level per user. We take the
      # max of the values produced by each group.
      if project.invited_groups.any? && project.allowed_to_share_with_group?
        project.project_group_links.each do |group_link|
          invited_access = max_invited_level_for_users(group_link, user_ids)
          merge_max!(access, invited_access)
        end
      end
    end

    access
  end

  def max_member_access(user_id)
    max_member_access_for_user_ids([user_id])[user_id]
  end

  private

  # For a given group, return the maximum access level for the user. This is the min of
  # the invited access level of the group and the access level of the user within the group.
  # For example, if the group has been given DEVELOPER access but the member has MASTER access,
  # the user should receive only DEVELOPER access.
  def max_invited_level_for_users(group_link, user_ids)
    invited_group = group_link.group
    capped_access_level = group_link.group_access
    access = invited_group.group_members.access_for_user_ids(user_ids)

    # If the user is not in the list, assume he/she does not have access
    missing_users = user_ids - access.keys
    missing_users.each { |id| access[id] = Gitlab::Access::NO_ACCESS }

    # Cap the maximum access by the invited level access
    access.each { |key, value| access[key] = [value, capped_access_level].min }
  end

  def fetch_members(level = nil)
    project_members = project.members
    group_members = group ? group.members : []
    invited_members = []

    if project.invited_groups.any? && project.allowed_to_share_with_group?
      project.project_group_links.includes(group: [:group_members]).each do |group_link|
        invited_group = group_link.group
        im = invited_group.members

        if level
          int_level = GroupMember.access_level_roles[level.to_s.singularize.titleize]

          # Skip group members if we ask for masters
          # but max group access is developers
          next if int_level > group_link.group_access

          # If we ask for developers and max
          # group access is developers we need to provide
          # both group master, developers as devs
          if int_level == group_link.group_access
            im.where("access_level >= ?)", group_link.group_access)
          else
            im.send(level)
          end
        end

        invited_members << im
      end

      invited_members = invited_members.flatten.compact
    end

    if level
      project_members = project_members.send(level)
      group_members = group_members.send(level) if group
    end

    user_ids = project_members.pluck(:user_id)
    user_ids.push(*invited_members.map(&:user_id)) if invited_members.any?
    user_ids.push(*group_members.pluck(:user_id)) if group

    User.where(id: user_ids)
  end

  def group
    project.group
  end

  def group_member_lock
    group && group.membership_lock
  end

  def merge_max!(first_hash, second_hash)
    first_hash.merge!(second_hash) { |_key, old, new| old > new ? old : new }
  end
end

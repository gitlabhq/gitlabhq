class GroupsFinder
  def execute(current_user, options = {})
    all_groups(current_user)
  end

  private

  def all_groups(current_user)
    group_ids = if current_user
                  if current_user.authorized_groups.any?
                    # User has access to groups
                    #
                    # Return only:
                    #   groups with public projects
                    #   groups with internal projects
                    #   groups with joined projects
                    #
                    Project.public_and_internal_only.pluck(:namespace_id) +
                      current_user.authorized_groups.pluck(:id)
                  else
                    # User has no group membership
                    #
                    # Return only:
                    #   groups with public projects
                    #   groups with internal projects
                    #
                    Project.public_and_internal_only.pluck(:namespace_id)
                  end
                else
                  # Not authenticated
                  #
                  # Return only:
                  #   groups with public projects
                  Project.public_only.pluck(:namespace_id)
                end

    Group.where("public IS TRUE OR id IN(?)", group_ids)
  end
end

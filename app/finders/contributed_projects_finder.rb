# frozen_string_literal: true

class ContributedProjectsFinder < UnionFinder
  def initialize(user)
    @user = user
  end

  # Finds the projects "@user" contributed to, limited to either public projects
  # or projects visible to the given user.
  #
  # current_user - When given the list of the projects is limited to those only
  #                visible by this user.
  #
  # ignore_visibility - When true the list of projects will include all contributed
  #                     projects, regardless of their visibility to the current_user
  #
  # Returns an ActiveRecord::Relation.
  def execute(current_user = nil, ignore_visibility: false)
    # Do not show contributed projects if the user profile is private.
    return Project.none unless can_read_profile?(current_user)

    segments = all_projects(current_user, ignore_visibility)

    find_union(segments, Project).with_namespace.order_id_desc
  end

  private

  def can_read_profile?(current_user)
    Ability.allowed?(current_user, :read_user_profile, @user)
  end

  def all_projects(current_user, ignore_visibility)
    return [@user.contributed_projects] if ignore_visibility

    projects = []

    projects << @user.contributed_projects.visible_to_user(current_user) if current_user
    projects << @user.contributed_projects.public_to_user(current_user)

    projects
  end
end

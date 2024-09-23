# frozen_string_literal: true

# Finds the projects "@user" contributed to, limited to either public projects
# or projects visible to the given user.
#
# Arguments:
#   user: User to find contributed projects for
#   current_user: The current user
#   params:
#     ignore_visibility: When true the list of projects will include all contributed
#                        projects, regardless of their visibility to the current_user.
#     min_access_level: Return only projects where user has at least the access level..
#     order_by: Order projects
#
# Returns an ActiveRecord::Relation.
class ContributedProjectsFinder
  attr_reader :user, :current_user, :params

  def initialize(user:, current_user: nil, params: {})
    @user = user
    @current_user = current_user
    @params = params
  end

  def execute
    # Do not show contributed projects if the user profile is private.
    return Project.none unless can_read_profile?(current_user)

    collection = init_collection

    collection.with_namespace.sort_by_attribute(params[:order_by] || 'id_desc')
  end

  private

  def can_read_profile?(current_user)
    Ability.allowed?(current_user, :read_user_profile, user)
  end

  def init_collection
    contributed_projects = user.contributed_projects

    return contributed_projects if params[:ignore_visibility]

    if current_user
      if params[:min_access_level].present?
        return contributed_projects.visible_to_user_and_access_level(current_user,
          params[:min_access_level])
      end

      return contributed_projects.public_or_visible_to_user(current_user)
    end

    contributed_projects.public_to_user
  end
end

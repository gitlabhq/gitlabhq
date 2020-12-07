# frozen_string_literal: true

class StarredProjectsFinder < ProjectsFinder
  include Gitlab::Allowable

  def initialize(user, params: {}, current_user: nil)
    @user = user

    super(
      params: params,
      current_user: current_user,
      project_ids_relation: user.starred_projects.select(:id)
    )
  end

  def execute
    # Do not show starred projects if the user has a private profile.
    return Project.none unless can?(current_user, :read_user_profile, @user)

    super
  end
end

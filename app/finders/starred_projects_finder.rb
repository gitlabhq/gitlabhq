# frozen_string_literal: true

class StarredProjectsFinder < ProjectsFinder
  def initialize(user, params: {}, current_user: nil)
    super(
      params: params,
      current_user: current_user,
      project_ids_relation: user.starred_projects.select(:id)
    )
  end
end

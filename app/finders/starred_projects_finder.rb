# frozen_string_literal: true

class StarredProjectsFinder < ProjectsFinder
  def initialize(user, params: {}, current_user: nil)
    project_ids = user.starred_projects.select(:id)

    super(params: params, current_user: current_user, project_ids_relation: project_ids)
  end
end

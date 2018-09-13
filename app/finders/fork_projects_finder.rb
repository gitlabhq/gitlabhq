# frozen_string_literal: true

class ForkProjectsFinder < ProjectsFinder
  # rubocop: disable CodeReuse/ActiveRecord
  def initialize(project, params: {}, current_user: nil)
    project_ids = project.forks.includes(:creator).select(:id)
    super(params: params, current_user: current_user, project_ids_relation: project_ids)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

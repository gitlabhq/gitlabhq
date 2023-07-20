# frozen_string_literal: true

module FindGroupProjects
  extend ActiveSupport::Concern

  def group_projects_for(user:, group:, exclude_shared: true)
    GroupProjectsFinder.new(
      group: group,
      current_user: user,
      options: { include_subgroups: true, exclude_shared: exclude_shared }
    ).execute
  end
end

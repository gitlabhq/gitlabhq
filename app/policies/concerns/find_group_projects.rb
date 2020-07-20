# frozen_string_literal: true

module FindGroupProjects
  extend ActiveSupport::Concern

  def group_projects_for(user:, group:, only_owned: true)
    GroupProjectsFinder.new(
      group: group,
      current_user: user,
      options: { include_subgroups: true, only_owned: only_owned }
    ).execute
  end
end

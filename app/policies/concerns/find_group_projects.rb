# frozen_string_literal: true

module FindGroupProjects
  extend ActiveSupport::Concern

  def group_projects_for(user:, group:)
    GroupProjectsFinder.new(
      group: group,
      current_user: user,
      options: { include_subgroups: true, only_owned: true }
    ).execute
  end
end

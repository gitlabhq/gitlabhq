# frozen_string_literal: true

class Dashboard::GroupsController < Dashboard::ApplicationController
  include GroupTree

  skip_cross_project_access_check :index

  feature_category :groups_and_projects

  urgency :low, [:index]

  def index
    groups = GroupsFinder.new(current_user, all_available: false).execute
    render_group_tree(groups)
  end
end

# frozen_string_literal: true

class Dashboard::GroupsController < Dashboard::ApplicationController
  include GroupTree

  skip_cross_project_access_check :index

  feature_category :groups_and_projects

  urgency :low, [:index]

  before_action only: :index do
    push_frontend_feature_flag(:archive_group)
  end

  def index
    groups = GroupsFinder.new(
      current_user,
      all_available: false,
      organization: Current.organization,
      active: safe_params[:active]
    ).execute

    render_group_tree(groups)
  end
end

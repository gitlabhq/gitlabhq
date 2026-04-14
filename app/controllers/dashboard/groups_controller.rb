# frozen_string_literal: true

class Dashboard::GroupsController < Dashboard::ApplicationController
  include SortingPreference
  include GroupTree

  skip_cross_project_access_check :index

  feature_category :groups_and_projects

  before_action :set_sorting

  urgency :low, [:index]

  def index
    groups = GroupsFinder.new(
      current_user,
      all_available: false,
      organization: Current.organization,
      active: safe_params[:active]
    ).execute

    render_group_tree(groups)
  end

  private

  def set_sorting
    @group_projects_sort = set_sort_order(Group::SORTING_PREFERENCE_FIELD, sort_value_recently_created)
  end
end

Dashboard::GroupsController.prepend_mod_with('Dashboard::GroupsController')

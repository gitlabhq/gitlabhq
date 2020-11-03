# frozen_string_literal: true

class FeatureFlagsUserListsFinder
  attr_reader :project, :current_user, :params

  def initialize(project, current_user, params = {})
    @project = project
    @current_user = current_user
    @params = params
  end

  def execute
    unless Ability.allowed?(current_user, :read_feature_flag, project)
      return Operations::FeatureFlagsUserList.none
    end

    items = feature_flags_user_lists
    by_search(items)
  end

  private

  def feature_flags_user_lists
    project.operations_feature_flags_user_lists
  end

  def by_search(items)
    if params[:search].present?
      items.for_name_like(params[:search])
    else
      items
    end
  end
end

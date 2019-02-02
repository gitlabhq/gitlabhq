# frozen_string_literal: true

class UsersStarProjectsFinder
  include CustomAttributesFilter

  attr_accessor :params

  def initialize(params = {}, project, current_user: nil)
    @params = params
    @project = project
    @current_user = current_user
  end

  def execute
    stars = UsersStarProject.all.order_id_desc
    stars = by_project(stars)
    stars = by_search(stars)
    stars = filter_visible_profiles(stars)

    stars
  end

  private

  def by_search(items)
    params[:search].present? ? items.search(params[:search]) : items
  end

  def by_project(items)
    items.by_project(@project)
  end

  def filter_visible_profiles(items)
    items.with_visible_profile(@current_user)
  end
end

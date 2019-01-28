# frozen_string_literal: true

class UsersStarProjectsFinder
  include CustomAttributesFilter

  attr_accessor :params

  def initialize(params = {})
    @params = params
  end

  def execute
    stars = UsersStarProject.all.order_id_desc
    stars = by_search(stars)
    stars = by_project(stars)

    stars
  end

  private

  def by_search(items)
    return items unless params[:search].present?

    items.search(params[:search])
  end

  def by_project(items)
    params[:project].present? ? items.by_project(params[:project]) : items
  end
end

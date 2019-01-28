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

    stars
  end

  private

  def by_search(items)
    params[:search].present? ? items.search(params[:search]) : items
  end
end

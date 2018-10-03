# frozen_string_literal: true

class GroupLabelsFinder
  attr_reader :group, :params

  def initialize(group, params = {})
    @group = group
    @params = params
  end

  def execute
    group.labels
      .optionally_search(params[:search])
      .order_by(params[:sort])
      .page(params[:page])
  end
end

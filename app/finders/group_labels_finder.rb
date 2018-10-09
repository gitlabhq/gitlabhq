# frozen_string_literal: true

class GroupLabelsFinder
  attr_reader :current_user, :group, :params

  def initialize(current_user, group, params = {})
    @current_user = current_user
    @group = group
    @params = params
  end

  def execute
    group.labels
      .optionally_subscribed_by(subscriber_id)
      .optionally_search(params[:search])
      .order_by(params[:sort])
      .page(params[:page])
  end

  private

  def subscriber_id
    current_user&.id if subscribed?
  end

  def subscribed?
    params[:subscribed] == 'true'
  end
end

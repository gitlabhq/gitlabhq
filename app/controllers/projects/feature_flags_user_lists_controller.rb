# frozen_string_literal: true

class Projects::FeatureFlagsUserListsController < Projects::ApplicationController
  before_action :authorize_admin_feature_flags_user_lists!
  before_action :user_list, only: [:edit, :show]

  feature_category :feature_flags
  urgency :low

  def index; end

  def new; end

  def edit; end

  def show; end

  private

  def user_list
    @user_list = project.operations_feature_flags_user_lists.find_by_iid!(params[:iid])
  end
end

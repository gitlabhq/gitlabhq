# frozen_string_literal: true

class Admin::KeysController < Admin::ApplicationController
  before_action :user, only: [:show, :destroy]

  feature_category :user_management

  def show
    @key = user.keys.find(params[:id])

    respond_to do |format|
      format.html
      format.js { head :ok }
    end
  end

  def destroy
    key = user.keys.find(params[:id])

    respond_to do |format|
      if key.destroy
        format.html do
          redirect_to keys_admin_user_path(user), status: :found, notice: _('User key was successfully removed.')
        end
      else
        format.html { redirect_to keys_admin_user_path(user), status: :found, alert: _('Failed to remove user key.') }
      end
    end
  end

  protected

  # rubocop: disable CodeReuse/ActiveRecord
  def user
    @user ||= User.find_by!(username: params[:user_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def key_params
    params.require(:user_id, :id)
  end
end

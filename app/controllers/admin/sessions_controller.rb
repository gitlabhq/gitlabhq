# frozen_string_literal: true

class Admin::SessionsController < ApplicationController
  include InternalRedirect

  before_action :user_is_admin!

  def new
    # Renders a form in which the admin can enter their password
  end

  def create
    if current_user_mode.enable_admin_mode!(password: params[:password])
      redirect_location = stored_location_for(:redirect) || admin_root_path
      redirect_to safe_redirect_path(redirect_location)
    else
      flash.now[:alert] = _('Invalid Login or password')
      render :new
    end
  end

  def destroy
    current_user_mode.disable_admin_mode!

    redirect_to root_path, status: :found, notice: _('Admin mode disabled')
  end

  private

  def user_is_admin!
    render_404 unless current_user&.admin?
  end
end

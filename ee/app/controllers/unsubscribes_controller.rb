class UnsubscribesController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @user = get_user
  end

  def create
    @user = get_user
    if @user
      @user.admin_unsubscribe!
      Notify.send_unsubscribed_notification(@user.id).deliver_later
    end

    redirect_to new_user_session_path, notice: 'You have been unsubscribed'
  end

  protected

  # rubocop: disable CodeReuse/ActiveRecord
  def get_user
    @email = Base64.urlsafe_decode64(params[:email])
    User.where(email: @email).first
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

module Public
  class UnsubscribesController < ApplicationController
    skip_before_filter :authenticate_user!,
                       :reject_blocked, :set_current_user_for_observers,
                       :add_abilities
    layout 'public_users'

    def show
      @user = get_user
    end

    def create
      @user = get_user
      @user.admin_unsubscribe!
      redirect_to new_user_session_path, notice: 'You have been unsubscribed'
    end

    protected
    def get_user
      @email = "#{params[:email]}.#{params[:format]}"
      User.where(email: @email).first!
    end
  end
end
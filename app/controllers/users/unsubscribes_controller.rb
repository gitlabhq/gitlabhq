# frozen_string_literal: true

module Users
  class UnsubscribesController < ApplicationController
    skip_before_action :authenticate_user!

    feature_category :user_profile

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
      @email = Base64.urlsafe_decode64(params.permit(:email)[:email])
      User.find_by(email: @email)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end

class Public::UsersController < ApplicationController
  skip_before_filter :authenticate_user!,
                     :reject_blocked, :set_current_user_for_observers,
                     :add_abilities

  layout 'public'

  def index
    @users = User.all
    @users = @users.where('username LIKE :query OR name LIKE :query',
        query: "%#{params[:search]}%") if params[:search].present?
    @users = @users.sort(@sort = params[:sort])
    @users = @users.page(params[:page]).per(20)
  end
end

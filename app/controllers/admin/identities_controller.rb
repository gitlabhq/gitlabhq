class Admin::IdentitiesController < Admin::ApplicationController
  before_action :user, only: [:destroy]

  def destroy
    identity = user.identities.find(params[:id])

    respond_to do |format|
      if identity.destroy
        format.html { redirect_to [:admin, user], notice: 'User identity was successfully removed.' }
      else
        format.html { redirect_to [:admin, user], alert: 'Failed to remove user identity.' }
      end
    end
  end

  protected

  def user
    @user ||= User.find_by!(username: params[:user_id])
  end
end

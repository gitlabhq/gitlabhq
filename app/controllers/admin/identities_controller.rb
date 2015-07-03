class Admin::IdentitiesController < Admin::ApplicationController
  before_action :user
  before_action :identity, except: :index

  def index
    @identities = @user.identities
  end

  def edit
  end

  def update
    if @identity.update_attributes(identity_params)
      redirect_to admin_user_identities_path(@user), notice: 'User identity was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    if @identity.destroy
      redirect_to admin_user_identities_path(@user), notice: 'User identity was successfully removed.'
    else
      redirect_to admin_user_identities_path(@user), alert: 'Failed to remove user identity.'
    end
  end

  protected

  def user
    @user ||= User.find_by!(username: params[:user_id])
  end

  def identity
    @identity ||= user.identities.find(params[:id])
  end

  def identity_params
    params.require(:identity).permit(:provider, :extern_uid)
  end
end

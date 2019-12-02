# frozen_string_literal: true

class Admin::IdentitiesController < Admin::ApplicationController
  before_action :user
  before_action :identity, except: [:index, :new, :create]

  def new
    @identity = Identity.new
  end

  def create
    @identity = Identity.new(identity_params)
    @identity.user_id = user.id

    if @identity.save
      redirect_to admin_user_identities_path(@user), notice: _('User identity was successfully created.')
    else
      render :new
    end
  end

  def index
    @identities = @user.identities
  end

  def edit
  end

  def update
    if @identity.update(identity_params)
      ::Users::RepairLdapBlockedService.new(@user).execute

      redirect_to admin_user_identities_path(@user), notice: _('User identity was successfully updated.')
    else
      render :edit
    end
  end

  def destroy
    if @identity.destroy
      ::Users::RepairLdapBlockedService.new(@user).execute

      redirect_to admin_user_identities_path(@user), status: :found, notice: _('User identity was successfully removed.')
    else
      redirect_to admin_user_identities_path(@user), status: :found, alert: _('Failed to remove user identity.')
    end
  end

  protected

  # rubocop: disable CodeReuse/ActiveRecord
  def user
    @user ||= User.find_by!(username: params[:user_id])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def identity
    @identity ||= user.identities.find(params[:id])
  end

  def identity_params
    params.require(:identity).permit(:provider, :extern_uid)
  end
end

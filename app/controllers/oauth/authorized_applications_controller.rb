class Oauth::AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  layout "profile"

  def destroy
    Doorkeeper::AccessToken.revoke_all_for(params[:id], current_resource_owner)
    redirect_to applications_profile_url, notice: I18n.t(:notice, scope: [:doorkeeper, :flash, :authorized_applications, :destroy])
  end
end

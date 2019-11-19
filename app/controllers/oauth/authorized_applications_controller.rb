# frozen_string_literal: true

class Oauth::AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  include PageLayoutHelper

  layout 'profile'

  def destroy
    if params[:token_id].present?
      current_resource_owner.oauth_authorized_tokens.find(params[:token_id]).revoke
    else
      Doorkeeper::AccessToken.revoke_all_for(params[:id], current_resource_owner)
    end

    redirect_to applications_profile_url,
                status: :found,
                notice: I18n.t(:notice, scope: [:doorkeeper, :flash, :authorized_applications, :destroy])
  end
end

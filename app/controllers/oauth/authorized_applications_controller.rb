# frozen_string_literal: true

class Oauth::AuthorizedApplicationsController < Doorkeeper::AuthorizedApplicationsController
  include PageLayoutHelper

  layout 'profile'

  def index
    respond_to do |format|
      format.html { render "errors/not_found", layout: "errors", status: :not_found }
      format.json { render json: "", status: :not_found }
    end
  end

  def destroy
    if params[:token_id].present?
      current_resource_owner.oauth_authorized_tokens.find(params[:token_id].to_s).revoke
    else
      Doorkeeper::Application.revoke_tokens_and_grants_for(params[:id].to_s, current_resource_owner)
    end

    redirect_to user_settings_applications_url,
      status: :found,
      notice: I18n.t(:notice, scope: [:doorkeeper, :flash, :authorized_applications, :destroy])
  end
end

# frozen_string_literal: true

class Profiles::WebauthnRegistrationsController < Profiles::ApplicationController
  feature_category :system_access

  def destroy
    Webauthn::DestroyService.new(current_user, current_user, params[:id]).execute

    redirect_to profile_two_factor_auth_path, status: :found, notice: _("Successfully deleted WebAuthn device.")
  end
end

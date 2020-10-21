# frozen_string_literal: true

class Profiles::WebauthnRegistrationsController < Profiles::ApplicationController
  feature_category :authentication_and_authorization

  def destroy
    webauthn_registration = current_user.webauthn_registrations.find(params[:id])
    webauthn_registration.destroy

    redirect_to profile_two_factor_auth_path, status: :found, notice: _("Successfully deleted WebAuthn device.")
  end
end

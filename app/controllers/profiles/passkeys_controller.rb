# frozen_string_literal: true

module Profiles
  class PasskeysController < Profiles::ApplicationController
    include AuthenticatesWithTwoFactor
    include Authn::WebauthnInstrumentation

    before_action :check_passkeys_available!
    skip_before_action :check_two_factor_requirement
    before_action :validate_current_password,
      only: [:create, :destroy],
      if: :current_password_required?

    feature_category :system_access

    helper_method :current_password_required?

    def new
      track_passkey_internal_event(
        event_name: 'register_passkey',
        status: 0,
        entry_point: passkey_instrumentation_params[:entry_point],
        user: current_user
      )

      setup_passkey_registration_page
    end

    def create
      result = Authn::Passkey::RegisterService.new(
        current_user,
        device_registration_params,
        session[:challenge]
      ).execute

      if result.success?
        track_passkey_internal_event(
          event_name: 'register_passkey',
          status: 1,
          user: current_user
        )

        session.delete(:challenge)

        redirect_to profile_two_factor_auth_path, status: :found, notice: result.message
      else
        track_passkey_internal_event(
          event_name: 'register_passkey',
          status: 2,
          user: current_user
        )

        redirect_to profile_two_factor_auth_path, status: :found, alert: result.message
      end
    end

    def destroy
      result = Authn::Passkey::DestroyService.new(current_user, current_user, destroy_params[:id]).execute

      if result.success?
        destroy_all_but_current_user_session!(current_user, session)

        redirect_to profile_two_factor_auth_path, status: :found, notice: result.message
      else
        redirect_to profile_two_factor_auth_path, status: :found, alert: result.message
      end
    end

    private

    def check_passkeys_available!
      render_404 unless Feature.enabled?(:passkeys, current_user)
    end

    def current_password_required?
      !current_user.password_automatically_set? && current_user.allow_password_authentication_for_web?
    end

    def validate_current_password
      return if current_user.valid_password?(validate_password_params[:current_password])

      current_user.increment_failed_attempts!

      error_message = { message: _('You must provide a valid current password.') }
      if validate_password_params[:action] == 'create'
        @webauthn_error = error_message
      else
        @error = error_message
      end

      setup_passkey_registration_page
    end

    def setup_passkey_registration_page
      @passkey ||= WebauthnRegistration.passkey.new
      @passkeys ||= get_passkeys

      current_user.user_detail.update!(webauthn_xid: WebAuthn.generate_user_id) unless current_user.webauthn_xid

      options = webauthn_options
      session[:challenge] = options.challenge

      gon.push(webauthn: { options: options })

      render :new
    end

    def get_passkeys
      current_user.passkeys.map do |passkey|
        {
          name: passkey.name,
          created_at: passkey.created_at,
          last_used_at: passkey.last_used_at,
          delete_path: profile_passkey_path(passkey)
        }
      end
    end

    def webauthn_options
      WebAuthn::Credential.options_for_create(
        user: {
          id: current_user.webauthn_xid,
          name: current_user.username,
          display_name: current_user.name
        },
        exclude: current_user.get_all_webauthn_credential_ids,
        authenticator_selection: {
          user_verification: 'required',
          resident_key: 'required'
        },
        rp: { name: 'GitLab' },
        extensions: { credProps: true }
      )
    end

    def device_registration_params
      params.require(:device_registration).permit(:device_response, :name)
    end

    def destroy_params
      params.permit(:id)
    end

    def validate_password_params
      params.permit(:current_password, :action)
    end

    def passkey_instrumentation_params
      params.permit(:entry_point)
    end
  end
end

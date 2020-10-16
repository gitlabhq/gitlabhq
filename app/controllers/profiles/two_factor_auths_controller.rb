# frozen_string_literal: true

class Profiles::TwoFactorAuthsController < Profiles::ApplicationController
  skip_before_action :check_two_factor_requirement
  before_action do
    push_frontend_feature_flag(:webauthn)
  end

  feature_category :authentication_and_authorization

  def show
    unless current_user.two_factor_enabled?
      current_user.otp_secret = User.generate_otp_secret(32)
    end

    unless current_user.otp_grace_period_started_at && two_factor_grace_period
      current_user.otp_grace_period_started_at = Time.current
    end

    Users::UpdateService.new(current_user, user: current_user).execute!

    if two_factor_authentication_required? && !current_user.two_factor_enabled?
      two_factor_authentication_reason(
        global: lambda do
          flash.now[:alert] =
            _('The global settings require you to enable Two-Factor Authentication for your account.')
        end,
        group: lambda do |groups|
          flash.now[:alert] = groups_notification(groups)
        end
      )

      unless two_factor_grace_period_expired?
        grace_period_deadline = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
        flash.now[:alert] = flash.now[:alert] + _(" You need to do this before %{grace_period_deadline}.") % { grace_period_deadline: l(grace_period_deadline) }
      end
    end

    @qr_code = build_qr_code
    @account_string = account_string

    if Feature.enabled?(:webauthn)
      setup_webauthn_registration
    else
      setup_u2f_registration
    end
  end

  def create
    otp_validation_result =
      ::Users::ValidateOtpService.new(current_user).execute(params[:pin_code])

    if otp_validation_result[:status] == :success
      ActiveSession.destroy_all_but_current(current_user, session)

      Users::UpdateService.new(current_user, user: current_user, otp_required_for_login: true).execute! do |user|
        @codes = user.generate_otp_backup_codes!
      end

      render 'create'
    else
      @error = _('Invalid pin code')
      @qr_code = build_qr_code

      if Feature.enabled?(:webauthn)
        setup_webauthn_registration
      else
        setup_u2f_registration
      end

      render 'show'
    end
  end

  # A U2F (universal 2nd factor) device's information is stored after successful
  # registration, which is then used while 2FA authentication is taking place.
  def create_u2f
    @u2f_registration = U2fRegistration.register(current_user, u2f_app_id, device_registration_params, session[:challenges])

    if @u2f_registration.persisted?
      session.delete(:challenges)
      redirect_to profile_two_factor_auth_path, notice: s_("Your U2F device was registered!")
    else
      @qr_code = build_qr_code
      setup_u2f_registration
      render :show
    end
  end

  def create_webauthn
    @webauthn_registration = Webauthn::RegisterService.new(current_user, device_registration_params, session[:challenge]).execute
    if @webauthn_registration.persisted?
      session.delete(:challenge)

      redirect_to profile_two_factor_auth_path, notice: s_("Your WebAuthn device was registered!")
    else
      @qr_code = build_qr_code

      setup_webauthn_registration

      render :show
    end
  end

  def codes
    Users::UpdateService.new(current_user, user: current_user).execute! do |user|
      @codes = user.generate_otp_backup_codes!
    end
  end

  def destroy
    result = TwoFactor::DestroyService.new(current_user, user: current_user).execute

    if result[:status] == :success
      redirect_to profile_account_path, status: :found, notice: s_('Two-factor authentication has been disabled successfully!')
    else
      redirect_to profile_account_path, status: :found, alert: result[:message]
    end
  end

  def skip
    if two_factor_grace_period_expired?
      redirect_to new_profile_two_factor_auth_path, alert: s_('Cannot skip two factor authentication setup')
    else
      session[:skip_two_factor] = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
      redirect_to root_path
    end
  end

  private

  def build_qr_code
    uri = current_user.otp_provisioning_uri(account_string, issuer: issuer_host)
    RQRCode.render_qrcode(uri, :svg, level: :m, unit: 3)
  end

  def account_string
    "#{issuer_host}:#{current_user.email}"
  end

  def issuer_host
    Gitlab.config.gitlab.host
  end

  # Setup in preparation of communication with a U2F (universal 2nd factor) device
  # Actual communication is performed using a Javascript API
  def setup_u2f_registration
    @u2f_registration ||= U2fRegistration.new
    @registrations = u2f_registrations
    u2f = U2F::U2F.new(u2f_app_id)

    registration_requests = u2f.registration_requests
    sign_requests = u2f.authentication_requests(current_user.u2f_registrations.map(&:key_handle))
    session[:challenges] = registration_requests.map(&:challenge)

    gon.push(u2f: { challenges: session[:challenges], app_id: u2f_app_id,
                    register_requests: registration_requests,
                    sign_requests: sign_requests })
  end

  def device_registration_params
    params.require(:device_registration).permit(:device_response, :name)
  end

  def setup_webauthn_registration
    @registrations = webauthn_registrations
    @webauthn_registration ||= WebauthnRegistration.new

    unless current_user.webauthn_xid
      current_user.user_detail.update!(webauthn_xid: WebAuthn.generate_user_id)
    end

    options = webauthn_options
    session[:challenge] = options.challenge

    gon.push(webauthn: { options: options, app_id: u2f_app_id })
  end

  # Adds delete path to u2f registrations
  # to reduce logic in view template
  def u2f_registrations
    current_user.u2f_registrations.map do |u2f_registration|
      {
          name: u2f_registration.name,
          created_at: u2f_registration.created_at,
          delete_path: profile_u2f_registration_path(u2f_registration)
      }
    end
  end

  def webauthn_registrations
    current_user.webauthn_registrations.map do |webauthn_registration|
      {
          name: webauthn_registration.name,
          created_at: webauthn_registration.created_at,
          delete_path: profile_webauthn_registration_path(webauthn_registration)
      }
    end
  end

  def webauthn_options
    WebAuthn::Credential.options_for_create(
      user: { id: current_user.webauthn_xid, name: current_user.username },
      exclude: current_user.webauthn_registrations.map { |c| c.credential_xid },
      authenticator_selection: { user_verification: 'discouraged' },
      rp: { name: 'GitLab' }
    )
  end

  def groups_notification(groups)
    group_links = groups.map { |group| view_context.link_to group.full_name, group_path(group) }.to_sentence
    leave_group_links = groups.map { |group| view_context.link_to (s_("leave %{group_name}") % { group_name: group.full_name }), leave_group_members_path(group), remote: false, method: :delete}.to_sentence

    s_(%{The group settings for %{group_links} require you to enable Two-Factor Authentication for your account. You can %{leave_group_links}.})
        .html_safe % { group_links: group_links.html_safe, leave_group_links: leave_group_links.html_safe }
  end
end

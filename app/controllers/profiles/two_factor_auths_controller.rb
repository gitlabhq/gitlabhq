# frozen_string_literal: true

class Profiles::TwoFactorAuthsController < Profiles::ApplicationController
  skip_before_action :check_two_factor_requirement
  before_action :ensure_verified_primary_email, only: [:show, :create]
  before_action :validate_current_password,
    only: [:create, :codes, :destroy, :destroy_otp, :destroy_webauthn, :create_webauthn],
    if: :current_password_required?
  before_action :update_current_user_otp!, only: [:show]

  helper_method :current_password_required?

  feature_category :system_access

  include SafeFormatHelper

  def show
    setup_show_page
  end

  def create
    otp_validation_result =
      ::Users::ValidateManualOtpService.new(current_user).execute(params[:pin_code])
    validated = (otp_validation_result[:status] == :success)

    if validated && current_user.otp_backup_codes?
      ActiveSession.destroy_all_but_current(current_user, session)
      Users::UpdateService.new(current_user, user: current_user, otp_required_for_login: true).execute!
      redirect_to profile_two_factor_auth_path, notice: _("Your Time-based OTP device was registered!")
    elsif validated
      ActiveSession.destroy_all_but_current(current_user, session)

      Users::UpdateService.new(current_user, user: current_user, otp_required_for_login: true).execute! do |user|
        @codes = user.generate_otp_backup_codes!
      end

      helpers.dismiss_two_factor_auth_recovery_settings_check

      render 'create'
    else
      @error = { message: _('Invalid pin code.') }
      @account_string = account_string

      setup_show_page

      render 'show'
    end
  end

  def create_webauthn
    @webauthn_registration = Webauthn::RegisterService.new(
      current_user,
      device_registration_params,
      session[:challenge]
    ).execute

    notice = _("Your WebAuthn device was registered!")
    if @webauthn_registration.persisted?
      session.delete(:challenge)

      if current_user.otp_backup_codes?
        redirect_to profile_two_factor_auth_path, notice: notice
      else

        Users::UpdateService.new(current_user, user: current_user).execute! do |user|
          @codes = current_user.generate_otp_backup_codes!
        end
        helpers.dismiss_two_factor_auth_recovery_settings_check
        flash[:notice] = notice
        render 'create'
      end
    else
      @qr_code = build_qr_code

      setup_webauthn_registration

      render :show
    end
  end

  def codes
    Users::UpdateService.new(current_user, user: current_user).execute! do |user|
      @codes = user.generate_otp_backup_codes!

      helpers.dismiss_two_factor_auth_recovery_settings_check
    end
  end

  def destroy
    result = TwoFactor::DestroyService.new(current_user, user: current_user).execute

    if result[:status] == :success
      redirect_to profile_account_path,
        status: :found,
        notice: _('Two-factor authentication has been disabled successfully!')
    else
      redirect_to profile_account_path, status: :found, alert: result[:message]
    end
  end

  def destroy_otp
    result = TwoFactor::DestroyOtpService.new(current_user, user: current_user).execute

    if result[:status] == :success
      redirect_to profile_two_factor_auth_path,
        status: :found,
        notice: _('One-time password authenticator has been deleted!')
    else
      redirect_to profile_two_factor_auth_path, status: :found, alert: result[:message]
    end
  end

  def destroy_webauthn
    Webauthn::DestroyService.new(current_user, current_user, params[:id]).execute

    redirect_to profile_two_factor_auth_path, status: :found, notice: _("Successfully deleted WebAuthn device.")
  end

  def skip
    if two_factor_grace_period_expired?
      redirect_to profile_two_factor_auth_url, alert: _('Cannot skip two factor authentication setup')
    else
      session[:skip_two_factor] = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
      redirect_to root_url
    end
  end

  private

  def update_current_user_otp!
    current_user.update_otp_secret! if current_user.needs_new_otp_secret?

    unless current_user.otp_grace_period_started_at && two_factor_grace_period
      current_user.otp_grace_period_started_at = Time.current
    end

    Users::UpdateService.new(current_user, user: current_user).execute!
  end

  def validate_current_password
    return if current_user.valid_password?(params[:current_password])

    current_user.increment_failed_attempts!

    error_message = { message: _('You must provide a valid current password.') }
    if params[:action] == 'create_webauthn'
      @webauthn_error = error_message
    elsif params[:action] == 'create'
      @otp_error = error_message
    else
      @error = error_message
    end

    setup_show_page

    render 'show'
  end

  def current_password_required?
    !current_user.password_automatically_set? && current_user.allow_password_authentication_for_web?
  end

  def build_qr_code
    uri = current_user.otp_provisioning_uri(account_string, issuer: issuer_host)
    svg = RQRCode::QRCode.new(uri, level: :m).as_svg(
      shape_rendering: "crispEdges",
      module_size: 3
    )

    doc = Nokogiri::XML(svg)
    svg_node = doc.at('svg')
    title = Nokogiri::XML::Node.new('title', doc)
    title.content = _('Generated QR Code')
    svg_node.children.before(title)

    doc.to_xml
  end

  def account_string
    "#{issuer_host}:#{current_user.email}"
  end

  def issuer_host
    Gitlab.config.gitlab.host
  end

  def device_registration_params
    params.require(:device_registration).permit(:device_response, :name)
  end

  def setup_webauthn_registration
    @registrations = webauthn_registrations
    @webauthn_registration ||= WebauthnRegistration.new

    current_user.user_detail.update!(webauthn_xid: WebAuthn.generate_user_id) unless current_user.webauthn_xid

    options = webauthn_options
    session[:challenge] = options.challenge

    gon.push(webauthn: { options: options, app_id: u2f_app_id })
  end

  def webauthn_registrations
    current_user.webauthn_registrations.map do |webauthn_registration|
      {
        name: webauthn_registration.name,
        created_at: webauthn_registration.created_at,
        delete_path: destroy_webauthn_profile_two_factor_auth_path(webauthn_registration)
      }
    end
  end

  def webauthn_options
    WebAuthn::Credential.options_for_create(
      user: { id: current_user.webauthn_xid, name: current_user.username },
      exclude: current_user.webauthn_registrations.map(&:credential_xid),
      authenticator_selection: { user_verification: 'discouraged' },
      rp: { name: 'GitLab' }
    )
  end

  def groups_notification(groups)
    group_links = groups.map { |group| view_context.link_to group.full_name, group_path(group) }.to_sentence
    leave_group_links = groups.map do |group|
      view_context.link_to (s_("leave %{group_name}") % { group_name: group.full_name }),
        leave_group_members_path(group),
        remote: false, method: :delete
    end.to_sentence

    safe_format(s_(
      'The group settings for %{group_links} require you to enable Two-Factor Authentication for your account. ' \
        'You can %{leave_group_links}.'
    ), group_links: group_links.html_safe, leave_group_links: leave_group_links.html_safe)
  end

  def ensure_verified_primary_email
    unless current_user.two_factor_enabled? || current_user.primary_email_verified?
      redirect_to profile_emails_path,
        notice: s_('You need to verify your primary email first before enabling Two-Factor Authentication.')
    end
  end

  def setup_show_page
    if two_factor_authentication_required? && !current_user.two_factor_enabled?
      two_factor_auth_actions = {
        global: ->(_) do
          _('The global settings require you to enable Two-Factor Authentication for your account.')
        end,
        admin_2fa: ->(_) do
          _('Administrator users are required to enable Two-Factor Authentication for their account.')
        end,
        group: ->(groups) do
          groups_notification(groups)
        end
      }
      message = execute_action_for_2fa_reason(two_factor_auth_actions)
      message = append_configure_2fa_later(message) unless two_factor_grace_period_expired?
      flash.now[:alert] = message
    end

    @qr_code = build_qr_code
    @account_string = account_string

    setup_webauthn_registration
  end

  def append_configure_2fa_later(message)
    grace_period_deadline = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
    render_to_string partial: 'configure_later_button',
      locals: { message: message, grace_period_deadline: grace_period_deadline }
  end
end

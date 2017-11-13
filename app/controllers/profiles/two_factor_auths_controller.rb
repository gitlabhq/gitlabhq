class Profiles::TwoFactorAuthsController < Profiles::ApplicationController
  skip_before_action :check_two_factor_requirement

  def show
    unless current_user.otp_secret
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
            'The global settings require you to enable Two-Factor Authentication for your account.'
        end,
        group: lambda do |groups|
          group_links = groups.map { |group| view_context.link_to group.full_name, group_path(group) }.to_sentence

          flash.now[:alert] = %{
            The group settings for #{group_links} require you to enable
            Two-Factor Authentication for your account.
          }.html_safe
        end
      )

      unless two_factor_grace_period_expired?
        grace_period_deadline = current_user.otp_grace_period_started_at + two_factor_grace_period.hours
        flash.now[:alert] << " You need to do this before #{l(grace_period_deadline)}."
      end
    end

    @qr_code = build_qr_code
    @account_string = account_string
    setup_u2f_registration
  end

  def create
    if current_user.validate_and_consume_otp!(params[:pin_code])
      Users::UpdateService.new(current_user, user: current_user, otp_required_for_login: true).execute! do |user|
        @codes = user.generate_otp_backup_codes!
      end

      render 'create'
    else
      @error = 'Invalid pin code'
      @qr_code = build_qr_code
      setup_u2f_registration
      render 'show'
    end
  end

  # A U2F (universal 2nd factor) device's information is stored after successful
  # registration, which is then used while 2FA authentication is taking place.
  def create_u2f
    @u2f_registration = U2fRegistration.register(current_user, u2f_app_id, u2f_registration_params, session[:challenges])

    if @u2f_registration.persisted?
      session.delete(:challenges)
      redirect_to profile_two_factor_auth_path, notice: "Your U2F device was registered!"
    else
      @qr_code = build_qr_code
      setup_u2f_registration
      render :show
    end
  end

  def codes
    Users::UpdateService.new(current_user, user: current_user).execute! do |user|
      @codes = user.generate_otp_backup_codes!
    end
  end

  def destroy
    current_user.disable_two_factor!

    redirect_to profile_account_path, status: 302
  end

  def skip
    if two_factor_grace_period_expired?
      redirect_to new_profile_two_factor_auth_path, alert: 'Cannot skip two factor authentication setup'
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
    @u2f_registrations = current_user.u2f_registrations
    u2f = U2F::U2F.new(u2f_app_id)

    registration_requests = u2f.registration_requests
    sign_requests = u2f.authentication_requests(@u2f_registrations.map(&:key_handle))
    session[:challenges] = registration_requests.map(&:challenge)

    gon.push(u2f: { challenges: session[:challenges], app_id: u2f_app_id,
                    register_requests: registration_requests,
                    sign_requests: sign_requests })
  end

  def u2f_registration_params
    params.require(:u2f_registration).permit(:device_response, :name)
  end
end

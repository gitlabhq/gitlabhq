class Profiles::AccountsController < Profiles::ApplicationController
  def show
    unless current_user.otp_secret
      current_user.otp_secret = User.generate_otp_secret(32)
    end

    unless current_user.otp_grace_period_started_at && two_factor_grace_period
      current_user.otp_grace_period_started_at = Time.current
    end

    # current_user.save! if current_user.changed?

    @user = current_user

    @qr_code = build_qr_code
  end

  def unlink
    provider = params[:provider]
    current_user.identities.find_by(provider: provider).destroy
    redirect_to profile_account_path
  end

  private

  def build_qr_code
    issuer = "#{issuer_host} | #{current_user.email}"
    uri = current_user.otp_provisioning_uri(current_user.email, issuer: issuer)
    RQRCode::render_qrcode(uri, :svg, level: :m, unit: 3)
  end

  def issuer_host
    Gitlab.config.gitlab.host
  end
end

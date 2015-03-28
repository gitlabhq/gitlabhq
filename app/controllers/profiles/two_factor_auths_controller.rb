class Profiles::TwoFactorAuthsController < ApplicationController
  def new
    issuer = "GitLab | #{current_user.email}"
    uri = current_user.otp_provisioning_uri(current_user.email, issuer: issuer)
    @qr_code = RQRCode::render_qrcode(uri, :svg, level: :l, unit: 2)
  end

  def create
    current_user.otp_required_for_login = true
    current_user.otp_secret = User.generate_otp_secret
    current_user.save!

    redirect_to profile_account_path
  end

  def destroy
    current_user.otp_required_for_login = false
    current_user.save!

    redirect_to profile_account_path
  end
end

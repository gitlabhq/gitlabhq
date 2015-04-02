class Profiles::TwoFactorAuthsController < ApplicationController
  def new
    unless current_user.otp_secret
      current_user.otp_secret = User.generate_otp_secret
      current_user.save!
    end

    @qr_code = build_qr_code
  end

  def create
    if current_user.valid_otp?(params[:pin_code])
      current_user.otp_required_for_login = true
      @codes = current_user.generate_otp_backup_codes!
      current_user.save!

      render 'create'
    else
      @error = 'Invalid pin code'
      @qr_code = build_qr_code
      render 'new'
    end
  end

  def codes
    @codes = current_user.generate_otp_backup_codes!
    current_user.save!
  end

  def destroy
    current_user.otp_required_for_login = false
    current_user.save!

    redirect_to profile_account_path
  end

  private

  def build_qr_code
    issuer = "GitLab | #{current_user.email}"
    uri = current_user.otp_provisioning_uri(current_user.email, issuer: issuer)
    RQRCode::render_qrcode(uri, :svg, level: :m, unit: 3)
  end
end

class RegistrationsController < Devise::RegistrationsController
  before_action :signup_enabled?
  include Recaptcha::Verify

  def new
    redirect_to(new_user_session_path)
  end

  def create
    if !Gitlab::Recaptcha.load_configurations! || verify_recaptcha
      if ip_is_spam_source(request.remote_ip)
        flash[:alert] = 'Could not create an account. This IP is listed for spam.'
        return render action: 'new'
      end

      super
    else
      flash[:alert] = "There was an error with the reCAPTCHA code below. Please re-enter the code."
      flash.delete :recaptcha_error
      render action: 'new'
    end
  end

  def destroy
    DeleteUserService.new(current_user).execute(current_user)

    respond_to do |format|
      format.html { redirect_to new_user_session_path, notice: "Account successfully removed." }
    end
  end

  protected

  def build_resource(hash=nil)
    super
  end

  def after_sign_up_path_for(_resource)
    new_user_session_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end

  private

  def signup_enabled?
    unless current_application_settings.signup_enabled?
      redirect_to(new_user_session_path)
    end
  end

  def ip_is_spam_source(ip)
    return false unless ApplicationSetting.current.ip_blocking_enabled

    return false if BlockingIp.whitelisted.find_by(ip: ip)

    dnswl_check = DNSXLCheck.create_from_list(DnsIpList.whitelist.all)
    return false if dnswl_check.test(ip)

    return true if BlockingIp.blacklisted.find_by(ip: ip)

    dnsbl_check = DNSXLCheck.create_from_list(DnsIpList.blacklist.all)
    dnsbl_check.test(ip)
  end

  def sign_up_params
    params.require(:user).permit(:username, :email, :name, :password, :password_confirmation)
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new(sign_up_params)
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end

class ConfirmationsController < Devise::ConfirmationsController

  # GET /resource/confirmation?confirmation_token=abcdef
  # overridden from Devise
  # we now allow duplicate unconfirmed emails to be added, to prevent
  # malicious individuals from blocking the valid owners of an email 
  def show
    resource = ConfirmationService.new(resource_class, params[:confirmation_token]).execute
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end

  def almost_there
    flash[:notice] = nil
    render layout: "devise_empty"
  end

  protected

  def after_resending_confirmation_instructions_path_for(resource)
    users_almost_there_path
  end

  def after_confirmation_path_for(resource_name, resource)
    # incoming resource can either be a :user or an :email
    if signed_in?(:user)
      after_sign_in(resource)
    else
      Gitlab::AppLogger.info("Email Confirmed: username=#{resource.username} email=#{resource.email} ip=#{request.remote_ip}")
      flash[:notice] += " Please sign in."
      new_session_path(:user)
    end
  end

  def after_sign_in(resource)
    after_sign_in_path_for(resource)
  end
end

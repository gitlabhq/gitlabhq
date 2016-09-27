class Profiles::AccountsController < Profiles::ApplicationController
  before_action :set_user, only: [:show, :private_token]

  def show
  end

  def private_token
    if params[:current_password]
      if @user.valid_password?(params[:current_password])
        @private_token = @user.private_token
      else
        @private_token_error = 'The password you entered is incorrect. Please try again.'
      end
    end

    respond_to do |format|
      format.html { render 'show' }

      format.json do
        if @private_token
          render json: { private_token: @private_token }
        else
          render status: :bad_request, json: { message: @private_token_error }
        end
      end
    end
  end

  def unlink
    provider = params[:provider]
    current_user.identities.find_by(provider: provider).destroy unless provider.to_s == 'saml'
    redirect_to profile_account_path
  end

  private

  def set_user
    @user = current_user
  end
end

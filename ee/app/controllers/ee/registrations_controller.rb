module EE
  module RegistrationsController
    extend ActiveSupport::Concern

    private

    def sign_up_params
      clean_params = params.require(:user).permit(:username, :email, :email_confirmation, :name, :password, :email_opted_in)

      clean_params[:email_opted_in_ip] = clean_params[:email_opted_in] == '1' ? request.remote_ip : nil

      clean_params
    end
  end
end

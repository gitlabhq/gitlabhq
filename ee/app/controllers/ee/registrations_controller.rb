module EE
  module RegistrationsController
    extend ActiveSupport::Concern
    
    private

    def sign_up_params
      params.require(:user).permit(:username, :email, :email_confirmation, :name, :password, :email_opted_in)
    end
  end
end

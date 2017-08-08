module EE
  module Users
    module BuildService

      private
      
      def signup_params
        [
          :email,
          :email_confirmation,
          :password_automatically_set,
          :name,
          :password,
          :username,
          :email_opted_in
        ]
      end
    end
  end
end

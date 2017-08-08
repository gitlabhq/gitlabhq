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
          :email_opted_in,
          :email_opted_in_ip,
          :email_opted_in_source,
          :email_opted_in_at
        ]
      end
    end
  end
end

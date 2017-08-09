module EE
  module Users
    module BuildService
      private

      def signup_params
        super + email_opted_in_params
      end

      def email_opted_in_params
        [
          :email_opted_in,
          :email_opted_in_ip,
          :email_opted_in_source_id,
          :email_opted_in_at
        ]
      end
    end
  end
end

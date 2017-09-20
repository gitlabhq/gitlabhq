module EE
  module Users
    module UpdateService
      include EE::Audit::Changes

      def initialize(current_user, user, params = {})
        @current_user = current_user

        super(user, params)
      end

      def execute(*args, &block)
        result = super(*args, &block)

        if result[:status] == :success
          audit_changes(:email, as: 'email address')
          audit_changes(:encrypted_password, as: 'password', skip_changes: true)
        end

        result
      end

      private

      def model
        @user
      end
    end
  end
end

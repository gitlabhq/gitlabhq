module EE
  module Users
    module UpdateService
      include EE::Audit::Changes

      private

      def notify_success(user_exists)
        notify_new_user(@user, nil) unless user_exists # rubocop:disable Gitlab/ModuleWithInstanceVariables

        audit_changes(:email, as: 'email address')
        audit_changes(:encrypted_password, as: 'password', skip_changes: true)

        success
      end

      def model
        @user
      end
    end
  end
end

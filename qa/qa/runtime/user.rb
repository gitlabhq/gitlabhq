# frozen_string_literal: true

module QA
  module Runtime
    # TODO: remove once all user handling logic is moved to UserStore class
    module User
      extend self

      def admin
        UserStore.admin_user
      end

      def default_username
        'root'
      end

      def default_email
        'admin@example.com'
      end

      def default_password
        '5iveL!fe'
      end

      def ldap_user?
        Runtime::Env.ldap_username.present? && Runtime::Env.ldap_password.present?
      end

      def ldap_username
        Runtime::Env.ldap_username || username
      end

      def ldap_password
        Runtime::Env.ldap_password || password
      end

      def admin_username
        Runtime::Env.admin_username || default_username
      end

      def admin_password
        Runtime::Env.admin_password || default_password
      end
    end
  end
end

QA::Runtime::User.extend_mod_with('Runtime::User', namespace: QA)

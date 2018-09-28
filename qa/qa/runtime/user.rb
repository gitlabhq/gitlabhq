module QA
  module Runtime
    module User
      extend self

      def default_username
        'root'
      end

      def default_password
        '5iveL!fe'
      end

      def username
        Runtime::Env.user_username || default_username
      end

      def password
        Runtime::Env.user_password || default_password
      end

      def ldap_user?
        Runtime::Env.ldap_username && Runtime::Env.ldap_password
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

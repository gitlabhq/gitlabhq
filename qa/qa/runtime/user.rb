module QA
  module Runtime
    module User
      extend self

      def default_username
        'root'
      end

      def username
        Runtime::Env.user_username || default_username
      end

      def password
        Runtime::Env.user_password || '5iveL!fe'
      end

      def ldap_user?
        Runtime::Env.user_type == 'ldap'
      end

      def ldap_username
        Runtime::Env.ldap_username || name
      end

      def ldap_password
        Runtime::Env.ldap_password || password
      end
    end
  end
end

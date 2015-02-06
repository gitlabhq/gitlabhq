require "krb5_auth"
# This calls helps to authenticate to Kerberos by providing username and password

module Gitlab
  module Kerberos
    class Authentication
      def self.login(login, password)
        return unless Devise.omniauth_providers.include?(:kerberos)
        return unless login.present? && password.present?

        auth = new(login, password)
        auth.login
      end

      def initialize(login, password)
        @login = login
        @password = password
        @krb5 = ::Krb5Auth::Krb5.new
      end

      def valid?
        @krb5.get_init_creds_password(@login, @password)
      rescue ::Krb5Auth::Krb5::Exception
        false
      end

      def login
        valid? && find_by_login(@login)
      end

      private

      def find_by_login(login)
        identity = ::Identity.
          where(provider: :kerberos).
          where('lower(extern_uid) = ?', login).last
        identity && identity.user
      end
    end
  end
end

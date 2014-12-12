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
        valid? && User.find_by(email: email)
      end

      def email
        @login + "@" + @krb5.get_default_realm.downcase
      end
    end
  end
end

# This calls helps to authenticate to Kerberos by providing username and password
module Gitlab
  module Kerberos
    class Authentication
      def self.kerberos_default_realm
        krb5 = krb5_class.new
        default_realm = krb5.get_default_realm
        krb5.close # release memory allocated by the krb5 library
        default_realm
      end

      def self.login(login, password)
        return unless Devise.omniauth_providers.include?(:kerberos)
        return unless login.present? && password.present?

        auth = new(login, password)
        auth.login
      end

      def self.krb5_class
        @krb5_class ||= begin
          require "krb5_auth"
          Krb5Auth::Krb5
        end
      end

      def initialize(login, password)
        @login = login
        @password = password
        @krb5 = self.class.krb5_class.new
      end

      def valid?
        @krb5.get_init_creds_password(@login, @password)
      rescue self.class.krb5_class::Exception
        false
      end

      def login
        # get_default_principal consistently returns the canonical Kerberos principal name, with realm
        valid? && find_by_login(@krb5.get_default_principal)
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def find_by_login(login)
        identity = ::Identity.with_extern_uid(:kerberos, login).take
        identity && identity.user
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

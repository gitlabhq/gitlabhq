# These calls help to authenticate to LDAP by providing username and password
#
# Since multiple LDAP servers are supported, it will loop through all of them
# until a valid bind is found
#

module Gitlab
  module LDAP
    class Authentication
      def self.login(login, password)
        return unless Gitlab::LDAP::Config.enabled?
        return unless login.present? && password.present?

        auth = nil
        # loop through providers until valid bind
        providers.find do |provider|
          auth = new(provider)
          auth.login(login, password) # true will exit the loop
        end

        # If (login, password) was invalid for all providers, the value of auth is now the last
        # Gitlab::LDAP::Authentication instance we tried.
        auth.user
      end

      def self.providers
        Gitlab::LDAP::Config.providers
      end

      attr_accessor :provider, :ldap_user

      def initialize(provider)
        @provider = provider
      end

      def login(login, password)
        @ldap_user = adapter.bind_as(
          filter: user_filter(login),
          size: 1,
          password: password
        )
      end

      def adapter
        OmniAuth::LDAP::Adaptor.new(config.options.symbolize_keys)
      end

      def config
        Gitlab::LDAP::Config.new(provider)
      end

      def user_filter(login)
        filter = Net::LDAP::Filter.equals(config.uid, login)

        # Apply LDAP user filter if present
        if config.user_filter.present?
          filter = Net::LDAP::Filter.join(
            filter,
            Net::LDAP::Filter.construct(config.user_filter)
          )
        end
        filter
      end

      def user
        return nil unless ldap_user
        Gitlab::LDAP::User.find_by_uid_and_provider(ldap_user.dn, provider)
      end
    end
  end
end

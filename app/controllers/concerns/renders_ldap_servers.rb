# frozen_string_literal: true

module RendersLdapServers
  extend ActiveSupport::Concern

  included do
    helper_method :ldap_servers
  end

  def ldap_servers
    @ldap_servers ||= if Gitlab::Auth::Ldap::Config.sign_in_enabled?
                        Gitlab::Auth::Ldap::Config.available_servers
                      else
                        []
                      end
  end
end

# frozen_string_literal: true

# Remove this file when virtual_registry_maven *and* dependency_proxy_read_write_scopes are removed
module VirtualRegistries
  def self.filter_token_scopes(scopes, current_user)
    return scopes if Feature.enabled?(:virtual_registry_maven, current_user) ||
      Feature.enabled?(:dependency_proxy_read_write_scopes, current_user)

    scopes - ::Gitlab::Auth.virtual_registry_scopes
  end
end

VirtualRegistries.prepend_mod

# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

# allow it to fail: it may do so when create_from_defaults is executed before migrations are actually done
begin
  session_expire_delay = Gitlab::CurrentSettings.current_application_settings.session_expire_delay
  Settings.gitlab['session_expire_delay'] = session_expire_delay || 10080
rescue StandardError
  Settings.gitlab['session_expire_delay'] ||= 10080
end

raw_config = if File.exist?(Rails.root.join('config/session_store.yml'))
               Rails.application.config_for(:session_store) || {}
             else
               {}
             end

# NOTE: `session_cookie_token_prefix` may be optionally injected into the environment
session_cookie_token_prefix = raw_config.fetch(:session_cookie_token_prefix, '')
if Gitlab.config.cell.enabled
  # NOTE: in the context of cells, the `session_cookie_token_prefix` must adhere to a specific format
  session_cookie_token_prefix_for_cell = "cell-#{Gitlab.config.cell.id}"
  if session_cookie_token_prefix.present? && session_cookie_token_prefix != session_cookie_token_prefix_for_cell
    raise "Given that cells are enabled, the session_cookie_token_prefix must be left blank or specifically set to " \
      "'#{session_cookie_token_prefix_for_cell}'. Currently it is set to: '#{session_cookie_token_prefix}'."
  end

  session_cookie_token_prefix = session_cookie_token_prefix_for_cell
end

cookie_key = if Rails.env.development?
               cookie_key_prefix = raw_config.fetch(:cookie_key, "_gitlab_session")
               # If config doesn't exist we preserve the current default behaviour, which is a unique postfix per GDK
               unique_key = raw_config.fetch(:unique_cookie_key_postfix, true)
               unique_key ? "#{cookie_key_prefix}_#{Digest::SHA256.hexdigest(Rails.root.to_s)}" : cookie_key_prefix
             elsif ::Gitlab.ee? && ::Gitlab::Geo.connected? && ::Gitlab::Geo.secondary?
               "_gitlab_session_geo_#{Digest::SHA256.hexdigest(GeoNode.current_node_name)}"
             else
               "_gitlab_session"
             end

::Redis::Store::Factory.prepend(Gitlab::Patch::RedisStoreFactory)

session_store_class, options = Gitlab::Sessions::StoreBuilder.new(cookie_key, session_cookie_token_prefix).prepare

Rails.application.configure do
  config.session_store(session_store_class, **options)
  config.middleware.insert_after session_store_class, Gitlab::Middleware::UnauthenticatedSessionExpiry
  config.action_dispatch.signed_cookie_salt = Settings['gitlab']['signed_cookie_salt'] || 'signed cookie'
  config.action_dispatch.authenticated_encrypted_cookie_salt =
    Settings['gitlab']['authenticated_encrypted_cookie_salt'] || 'authenticated encrypted cookie'
end

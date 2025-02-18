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

cell_id = Gitlab.config.cell.id
session_cookie_token_prefix = if raw_config.fetch(:session_cookie_token_prefix, '').present?
                                raw_config.fetch(:session_cookie_token_prefix)
                              elsif cell_id.present?
                                "cell-#{cell_id}"
                              else
                                ""
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

ENV['USE_REDIS_CACHE_STORE_AS_SESSION_STORE'] = 'true' if Rails.env.test? || Rails.env.development?

session_store_class, options = Gitlab::Sessions::StoreBuilder.new(cookie_key, session_cookie_token_prefix).prepare

Rails.application.configure do
  config.session_store(session_store_class, **options)
  config.middleware.insert_after session_store_class, Gitlab::Middleware::UnauthenticatedSessionExpiry
end

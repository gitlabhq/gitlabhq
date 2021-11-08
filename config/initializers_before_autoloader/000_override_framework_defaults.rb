# frozen_string_literal: true

# This contains configuration from Rails upgrades to override the new defaults so that we
# keep existing behavior.
#
# For boolean values, the new default is the opposite of the value being set in this file.
# For other types, the new default is noted in the comments. These are also documented in
# https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
#
# To switch a setting to the new default value, we just need to delete the specific line here.

Rails.application.configure do
  # Rails 6.1
  config.action_dispatch.cookies_same_site_protection = nil # New default is :lax
  config.action_dispatch.ssl_default_redirect_status = nil # New default is 308
  ActiveSupport.utc_to_local_returns_utc_offset_times = false
  config.action_controller.urlsafe_csrf_tokens = false
  config.action_view.preload_links_header = false

  # Rails 5.2
  config.action_dispatch.use_authenticated_cookie_encryption = false
  config.active_support.use_authenticated_message_encryption = false
  config.active_support.hash_digest_class = ::Digest::MD5 # New default is ::Digest::SHA1
  config.action_controller.default_protect_from_forgery = false
  config.action_view.form_with_generates_ids = false

  # Rails 5.1
  config.assets.unknown_asset_fallback = true

  # Rails 5.0
  config.action_controller.per_form_csrf_tokens = false
  config.action_controller.forgery_protection_origin_check = false
  ActiveSupport.to_time_preserves_timezone = false
  config.ssl_options = {} # New default is { hsts: { subdomains: true } }
end

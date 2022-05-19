# frozen_string_literal: true

module AccessTokensHelper
  include AccountsHelper
  include ApplicationHelper

  def scope_description(prefix)
    prefix == :project_access_token ? [:doorkeeper, :project_access_token_scope_desc] : [:doorkeeper, :scope_desc]
  end

  def tokens_app_data
    {
      feed_token: {
        enabled: !Gitlab::CurrentSettings.disable_feed_token,
        token: current_user.feed_token,
        reset_path: reset_feed_token_profile_path
      },
      incoming_email_token: {
        enabled: incoming_email_token_enabled?,
        token: current_user.enabled_incoming_email_token,
        reset_path: reset_incoming_email_token_profile_path
      },
      static_object_token: {
        enabled: static_objects_external_storage_enabled?,
        token: current_user.enabled_static_object_token,
        reset_path: reset_static_object_token_profile_path
      }
    }.to_json
  end

  def expires_at_field_data
    {
      min_date: 1.day.from_now.iso8601
    }
  end
end

AccessTokensHelper.prepend_mod

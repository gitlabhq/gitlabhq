# frozen_string_literal: true

module AccessTokensHelper
  include AccountsHelper
  include ApplicationHelper

  def scope_description(prefix)
    case prefix
    when :project_access_token
      [:doorkeeper, :project_access_token_scope_desc]
    when :group_access_token
      [:doorkeeper, :group_access_token_scope_desc]
    else
      [:doorkeeper, :scope_desc]
    end
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
      min_date: 1.day.from_now.iso8601,
      max_date: max_date_allowed
    }
  end

  private

  def max_date_allowed
    return unless Gitlab::CurrentSettings.require_personal_access_token_expiry?

    ::PersonalAccessToken.max_expiration_lifetime_in_days.days.from_now.iso8601
  end
end

AccessTokensHelper.prepend_mod

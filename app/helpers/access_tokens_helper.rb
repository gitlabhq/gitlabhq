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

  def filter_sort_scopes(scopes, sources)
    scopes.select { |scope| ::Gitlab::Auth::UI_SCOPES_ORDERED_BY_PERMISSION.include?(scope) }
    .sort_by { |scope| ::Gitlab::Auth::UI_SCOPES_ORDERED_BY_PERMISSION.index(scope) }
    .map do |value|
      {
        value: value,
        text: t(value, scope: sources)
      }
    end
  end

  def personal_access_token_data(token, user = current_user)
    sources = scope_description(:personal_access_token)
    scopes = ::Gitlab::Auth.available_scopes_for(user)
    {
      access_token: {
        **expires_at_field_data,
        available_scopes: filter_sort_scopes(scopes, sources).to_json,
        name: token[:name],
        description: token[:description],
        scopes: token[:scopes].to_json,
        create: user_settings_personal_access_tokens_url,
        new: new_user_settings_personal_access_token_path,
        revoke: expose_url(api_v4_personal_access_tokens_path),
        rotate: expose_url(api_v4_personal_access_tokens_path),
        show: "#{expose_url(api_v4_personal_access_tokens_path)}?user_id=:id"
      }
    }
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

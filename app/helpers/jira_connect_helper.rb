# frozen_string_literal: true

module JiraConnectHelper
  def jira_connect_app_data(subscriptions, installation)
    skip_groups = subscriptions.map(&:namespace_id).join(',')

    {
      groups_path: api_v4_groups_path(params: { skip_groups: skip_groups }),
      subscriptions: subscriptions.map { |s| serialize_subscription(s) }.to_json,
      subscriptions_path: jira_connect_subscriptions_path(format: :json),
      gitlab_user_path: current_user ? user_path(current_user) : nil,
      oauth_metadata: jira_connect_oauth_data(installation).to_json,
      public_key_storage_enabled: Gitlab::CurrentSettings.jira_connect_public_key_storage_enabled?
    }
  end

  private

  def jira_connect_oauth_data(installation)
    oauth_instance_url = installation.oauth_authorization_url

    {
      oauth_authorize_url: Gitlab::Utils.append_path(oauth_instance_url, oauth_authorize_path),
      oauth_token_path: oauth_token_path,
      state: oauth_state,
      oauth_token_payload: {
        grant_type: :authorization_code,
        client_id: Gitlab::CurrentSettings.jira_connect_application_key,
        redirect_uri: jira_connect_oauth_callbacks_url
      }
    }
  end

  def oauth_state
    @oauth_state ||= SecureRandom.hex(32)
  end

  def serialize_subscription(subscription)
    {
      group: {
        name: subscription.namespace.name,
        avatar_url: subscription.namespace.avatar_url,
        full_name: subscription.namespace.full_name,
        description: subscription.namespace.description
      },
      created_at: subscription.created_at,
      unlink_path: jira_connect_subscription_path(subscription)
    }
  end

  def relative_url_root
    Gitlab.config.gitlab.relative_url_root.presence
  end

  def oauth_authorize_path
    oauth_authorize_path = oauth_authorization_path(
      client_id: Gitlab::CurrentSettings.jira_connect_application_key,
      response_type: 'code',
      scope: 'api',
      redirect_uri: jira_connect_oauth_callbacks_url,
      state: oauth_state
    )

    oauth_authorize_path.delete_prefix(relative_url_root)
  end
end

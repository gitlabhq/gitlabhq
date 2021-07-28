# frozen_string_literal: true

class JiraConnect::AppDataSerializer
  include Gitlab::Routing
  include ::API::Helpers::RelatedResourcesHelpers

  def initialize(subscriptions, signed_in)
    @subscriptions = subscriptions
    @signed_in = signed_in
  end

  def as_json
    skip_groups = @subscriptions.map(&:namespace_id)

    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER, skip_groups: skip_groups }),
      subscriptions: JiraConnect::SubscriptionEntity.represent(@subscriptions).as_json,
      subscriptions_path: jira_connect_subscriptions_path,
      login_path: signed_in? ? nil : jira_connect_users_path
    }
  end

  private

  def signed_in?
    !!@signed_in
  end
end

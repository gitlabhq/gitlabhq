# frozen_string_literal: true

class JiraConnect::AppDataSerializer
  include Gitlab::Routing
  include ::API::Helpers::RelatedResourcesHelpers

  def initialize(subscriptions)
    @subscriptions = subscriptions
  end

  def as_json
    skip_groups = @subscriptions.map(&:namespace_id).join(',')

    {
      groups_path: api_v4_groups_path(params: { min_access_level: Gitlab::Access::MAINTAINER, skip_groups: skip_groups }),
      subscriptions: JiraConnect::SubscriptionEntity.represent(@subscriptions).as_json,
      subscriptions_path: jira_connect_subscriptions_path
    }
  end
end

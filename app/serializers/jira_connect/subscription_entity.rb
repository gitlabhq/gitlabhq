# frozen_string_literal: true

class JiraConnect::SubscriptionEntity < Grape::Entity
  include Gitlab::Routing

  expose :created_at
  expose :unlink_path do |subscription|
    jira_connect_subscription_path(subscription)
  end
  expose :namespace, with: JiraConnect::GroupEntity, as: :group
end

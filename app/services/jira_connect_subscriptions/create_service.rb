# frozen_string_literal: true

module JiraConnectSubscriptions
  class CreateService < ::JiraConnectSubscriptions::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      unless namespace && can?(current_user, :create_jira_connect_subscription, namespace)
        return error('Invalid namespace. Please make sure you have sufficient permissions', 401)
      end

      create_subscription
    end

    private

    def create_subscription
      subscription = JiraConnectSubscription.new(installation: jira_connect_installation, namespace: namespace)

      if subscription.save
        success
      else
        error(subscription.errors.full_messages.join(', '), 422)
      end
    end

    def namespace
      strong_memoize(:namespace) do
        Namespace.find_by_full_path(params[:namespace_path])
      end
    end
  end
end

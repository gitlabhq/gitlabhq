# frozen_string_literal: true

module JiraConnectSubscriptions
  class DestroyService
    attr_accessor :subscription, :jira_user

    def initialize(subscription, jira_user)
      @subscription = subscription
      @jira_user = jira_user
    end

    def execute
      unless subscription
        return ServiceResponse.error(message: _('Invalid JiraConnectSubscriptions'),
          reason: :unprocessable_entity)
      end

      return ServiceResponse.error(message: _('Forbidden'), reason: :forbidden) unless can_administer_jira?

      namespace_id = subscription.namespace_id

      if subscription.destroy
        deactivate_jira_cloud_app_integrations(namespace_id)

        return ServiceResponse.success
      end

      ServiceResponse.error(
        message: subscription.errors.full_messages.to_sentence,
        reason: :unprocessable_entity
      )
    end

    private

    def can_administer_jira?
      jira_user&.jira_admin?
    end

    def deactivate_jira_cloud_app_integrations(namespace_id)
      JiraConnect::JiraCloudAppDeactivationWorker.perform_async(namespace_id)
    end
  end
end

# frozen_string_literal: true

module JiraConnectSubscriptions
  class DestroyService
    BATCH_SIZE = 1_000

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

      deactivate_jira_cloud_app_integrations!

      return ServiceResponse.success if subscription.destroy

      ServiceResponse.error(
        message: subscription.errors.full_messages.to_sentence,
        reason: :unprocessable_entity
      )
    end

    private

    def can_administer_jira?
      jira_user&.jira_admin?
    end

    def deactivate_jira_cloud_app_integrations!
      return unless Feature.enabled?(:enable_jira_connect_configuration) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- flag must be global

      integration = Integrations::JiraCloudApp.for_group(@subscription.namespace_id).first

      return unless integration

      Integrations::JiraCloudApp.transaction do
        integration.inherit_from_id = nil
        integration.deactivate!
        Integration.descendants_from_self_or_ancestors_from(integration).each_batch(of: BATCH_SIZE) do |records|
          records.update!(active: false)
        end
      end
    end
  end
end

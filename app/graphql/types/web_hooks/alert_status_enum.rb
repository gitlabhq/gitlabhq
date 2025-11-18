# frozen_string_literal: true

module Types
  module WebHooks
    class AlertStatusEnum < BaseEnum
      graphql_name 'WebhookAlertStatus'
      description 'Webhook auto-disabling alert status'

      value 'EXECUTABLE',
        description: 'Webhook is executable.',
        value: 'executable'

      value 'TEMPORARILY_DISABLED',
        description: 'Webhook has been temporarily disabled and will be automatically re-enabled.',
        value: 'temporarily_disabled'

      value 'DISABLED',
        description: 'Webhook has been permanently disabled and will not be automatically re-enabled.',
        value: 'disabled'
    end
  end
end

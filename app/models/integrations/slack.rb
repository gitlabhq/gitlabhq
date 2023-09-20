# frozen_string_literal: true

module Integrations
  class Slack < BaseSlackNotification
    include SlackMattermostNotifier
    include SlackMattermostFields

    def title
      'Slack notifications'
    end

    def description
      'Send notifications about project events to Slack.'
    end

    def self.to_param
      'slack'
    end

    def self.webhook_help
      'https://hooks.slack.com/services/…'
    end

    private

    override :metrics_key_prefix
    def metrics_key_prefix
      'i_ecosystem_slack_service'
    end
  end
end

# frozen_string_literal: true

module Integrations
  class GitlabSlackApplication < Integration
    attribute :alert_events, default: false
    attribute :commit_events, default: false
    attribute :confidential_issues_events, default: false
    attribute :confidential_note_events, default: false
    attribute :deployment_events, default: false
    attribute :issues_events, default: false
    attribute :job_events, default: false
    attribute :merge_requests_events, default: false
    attribute :note_events, default: false
    attribute :pipeline_events, default: false
    attribute :push_events, default: false
    attribute :tag_push_events, default: false
    attribute :vulnerability_events, default: false
    attribute :wiki_page_events, default: false

    has_one :slack_integration, foreign_key: :integration_id, inverse_of: :integration
    delegate :bot_access_token, :bot_user_id, to: :slack_integration, allow_nil: true

    include Integrations::Base::SlackNotification
    include SlackMattermostFields

    def self.title
      s_('Integrations|GitLab for Slack app')
    end

    def self.description
      s_('Integrations|Enable slash commands and notifications for a Slack workspace.')
    end

    def self.to_param
      'gitlab_slack_application'
    end

    override :manual_activation?
    def manual_activation?
      false
    end

    override :test
    def test(_data)
      failures = test_notification_channels

      { success: failures.blank?, result: failures }
    end

    # The form fields of this integration are editable only after the Slack App installation
    # flow has been completed, which causes the integration to become activated/enabled.
    override :editable?
    def editable?
      activated?
    end

    override :fields
    def fields
      return [] unless editable?

      super
    end

    override :sections
    def sections
      return [] unless editable?

      super.drop(1)
    end

    def self.webhook_help
      # no-op
    end

    override :configurable_events
    def configurable_events
      return [] unless editable?

      super
    end

    override :requires_webhook?
    def self.requires_webhook?
      false
    end

    def upgrade_needed?
      slack_integration.present? && slack_integration.upgrade_needed?
    end

    private

    override :notify
    def notify(message, opts)
      channels = Array(opts[:channel])
      return false if channels.empty?

      payload = {
        attachments: message.attachments,
        text: message.pretext,
        unfurl_links: false,
        unfurl_media: false
      }

      successes = channels.map do |channel|
        notify_slack_channel!(channel, payload)
      end

      successes.any?
    end

    def notify_slack_channel!(channel, payload)
      response = api_client.post(
        'chat.postMessage',
        payload.merge(channel: channel)
      )

      log_error('Slack API error when notifying', api_response: response.parsed_response) unless response['ok']

      response['ok']
    rescue *Gitlab::HTTP::HTTP_ERRORS => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e,
        {
          integration_id: id,
          slack_integration_id: slack_integration.id
        }
      )

      false
    end

    def api_client
      @slack_api ||= ::Slack::API.new(slack_integration)
    end

    def test_notification_channels
      return if unique_channels.empty?
      return s_('Integrations|GitLab for Slack app must be reinstalled to enable notifications') unless bot_access_token

      test_payload = {
        text: 'Test',
        user: bot_user_id
      }

      not_found_channels = unique_channels.first(10).select do |channel|
        test_payload[:channel] = channel

        response = ::Slack::API.new(slack_integration).post('chat.postEphemeral', test_payload)
        response['error'] == 'channel_not_found'
      end

      return if not_found_channels.empty?

      format(
        s_(
          'Integrations|Unable to post to %{channel_list}, ' \
          'please add the GitLab Slack app to any private Slack channels'
        ),
        channel_list: not_found_channels.to_sentence
      )
    end

    override :metrics_key_prefix
    def metrics_key_prefix
      'i_integrations_gitlab_for_slack_app'
    end
  end
end

# frozen_string_literal: true

module Integrations
  class SlackEventWorker
    include ApplicationWorker

    EVENTS = {
      'app_home_opened' => SlackEvents::AppHomeOpenedService
    }.freeze

    feature_category :integrations
    data_consistency :delayed
    urgency :low
    deduplicate :until_executed
    idempotent!
    worker_has_external_dependencies!

    def self.event?(slack_event)
      EVENTS.key?(slack_event)
    end

    def perform(args)
      args = args.with_indifferent_access

      log_extra_metadata_on_done(:slack_event, args[:slack_event])
      log_extra_metadata_on_done(:slack_user_id, args.dig(:params, :event, :user))
      log_extra_metadata_on_done(:slack_workspace_id, args.dig(:params, :team_id))

      unless self.class.event?(args[:slack_event])
        Sidekiq.logger.error(
          message: 'Unknown slack_event',
          slack_event: args[:slack_event]
        )

        return
      end

      # Ensure idempotency by taking out an exclusive lease keyed to `params.event_id`.
      # The `event_id` is "a unique identifier for this specific event, globally unique
      # across all workspaces" and guaranteed to be present as part of the Slack event JSON schema.
      # See https://api.slack.com/types/event.
      lease = Gitlab::ExclusiveLease.new("slack_event:#{args[:params][:event_id]}", timeout: 1.hour.to_i)
      return unless lease.try_obtain

      service_class = EVENTS[args[:slack_event]]
      response = service_class.new(args[:params]).execute

      lease.cancel if response.error?
    rescue StandardError => e
      lease.cancel
      raise e
    end
  end
end

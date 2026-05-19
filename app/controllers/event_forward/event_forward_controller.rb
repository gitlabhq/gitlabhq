# frozen_string_literal: true

module EventForward
  class EventForwardController < BaseActionController
    include SessionlessAuthentication

    DEDICATED_SUFFIX = 'dedicated'
    SELF_MANAGED_SUFFIX = 'sm'
    EDITOR_TELEMETRY_HEADER = 'HTTP_X_GITLAB_EDITOR_TELEMETRY'

    before_action :authenticate_sessionless_user!, if: :editor_extension_request?

    def forward
      process_events
      head :ok
    end

    private

    def authenticate_sessionless_user!
      super(:editor_extension)
    end

    def process_events
      tracker = Gitlab::Tracking.tracker
      event_eligibility_checker = Gitlab::Tracking::EventEligibilityChecker.new

      payload = Gitlab::Json.safe_parse(request.raw_post)

      events_to_forward = payload['data'].select do |event|
        event_eligibility_checker.eligible?(event['se_ac'], event['aid'])
      end

      events_to_forward.each do |event|
        update_app_id(event)
        enrich_with_standard_context(event) if editor_extension_request?
        tracker.emit_event_payload(event)

        if Rails.env.development? && event['cx']
          context = Gitlab::Json.safe_parse(Base64.decode64(event['cx']))
          Gitlab::Tracking::Destinations::SnowplowContextValidator.new.validate!(context['data'])
        end
      end

      logger.info("Enqueued events for forwarding. Count: #{events_to_forward.size}")
    end

    def editor_extension_request?
      request.env[EDITOR_TELEMETRY_HEADER].present?
    end

    def update_app_id(event)
      app_id = event['aid']

      return unless app_id
      return if app_id.ends_with?(suffix)

      event['aid'] = "#{app_id}#{suffix}"
    end

    def enrich_with_standard_context(event)
      default_payload = { 'schema' => 'iglu:com.snowplowanalytics.snowplow/contexts/jsonschema/1-0-1', 'data' => [] }

      context_payload = begin
        (event['cx'] && Gitlab::Json.safe_parse(Base64.strict_decode64(event['cx']))) || default_payload
      rescue JSON::ParserError, ArgumentError
        default_payload
      end

      already_enriched = context_payload['data'].any? do |ctx|
        ctx['schema'] == Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL
      end
      return if already_enriched

      context_payload['data'] << {
        'schema' => Gitlab::Tracking::StandardContext::GITLAB_STANDARD_SCHEMA_URL,
        'data' => Gitlab::Tracking::StandardContext.new(user: current_user).to_h
      }

      event['cx'] = Base64.strict_encode64(Gitlab::Json.dump(context_payload))
    end

    def logger
      @logger ||= EventForward::Logger.build
    end

    def suffix
      @suffix ||= if ::Gitlab::CurrentSettings.gitlab_dedicated_instance?
                    "_#{DEDICATED_SUFFIX}"
                  else
                    "_#{SELF_MANAGED_SUFFIX}"
                  end
    end
  end
end

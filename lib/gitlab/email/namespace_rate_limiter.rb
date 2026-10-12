# frozen_string_literal: true

module Gitlab
  module Email
    # Counts outbound emails per root namespace against two ApplicationRateLimiter
    # windows and suppresses a batch all-or-none once either is exhausted. Each
    # feature passes its own bucket keys, so exhausting one feature's quota never
    # throttles another; the numeric threshold is shared.
    #
    # Threshold is read from the service_desk_outbound_emails_per_hour/_per_day
    # plan_limit columns for every feature. Accepted debt: those service_desk_*
    # columns are the de-facto outbound-email cap for non-Service-Desk features
    # too.
    #
    class NamespaceRateLimiter
      extend ::Gitlab::Loggable
      include Gitlab::Utils::StrongMemoize
      include ::Gitlab::Loggable

      HOURLY_THRESHOLD_LIMIT_NAME = :service_desk_outbound_emails_per_hour
      DAILY_THRESHOLD_LIMIT_NAME = :service_desk_outbound_emails_per_day
      NO_LIMIT = 0

      # Overshoot policy: how a batch that crosses a window boundary is handled.
      # :soft_cap sends the tripping batch and suppresses only once a window is
      # already exhausted, so an oversized batch (larger than the window) still
      # goes through once instead of being suppressed forever; a limit of N can
      # therefore let more than N through on the batch that overshoots. :hard_cap
      # charges the batch up front and suppresses the batch that trips the window,
      # which is stricter but can never fit a batch larger than the window.
      #
      OVERSHOOT_MODES = [:soft_cap, :hard_cap].freeze

      # Charges a batch for a project's root namespace, handling the shared
      # caller boilerplate: builds the log context and charges the batch.
      # Returns true when sending should be suppressed.
      #
      # Service Desk does not use this: it always has a project and reuses the
      # limiter instance for its suppression notice, so it builds the instance
      # directly.
      #
      def self.rate_limit_batch_for_project!(
        project:, class_name:, hourly_bucket:, daily_bucket:, feature_flag:,
        log_message:, count:, overshoot: :soft_cap)
        log_context = {
          Labkit::Fields::CLASS_NAME => class_name,
          Labkit::Fields::GL_NAMESPACE_ID => project.namespace_id,
          Labkit::Fields::GL_PROJECT_ID => project.id
        }

        new(
          root_namespace: project.root_namespace,
          hourly_bucket: hourly_bucket,
          daily_bucket: daily_bucket,
          feature_flag: feature_flag,
          log_message: log_message,
          log_context: log_context,
          overshoot: overshoot
        ).rate_limit_batch!(count)
      end

      # hourly_bucket/daily_bucket must be rules registered in
      # Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits;
      # an unregistered key raises when first charged, not at boot.
      #
      def initialize(
        root_namespace:, hourly_bucket:, daily_bucket:, feature_flag:, log_message:,
        log_context: {}, overshoot: :soft_cap)
        raise ArgumentError, "unknown overshoot mode: #{overshoot}" unless OVERSHOOT_MODES.include?(overshoot)

        @root_namespace = root_namespace
        @hourly_bucket = hourly_bucket
        @daily_bucket = daily_bucket
        @feature_flag = feature_flag
        @log_message = log_message
        @log_context = log_context
        @overshoot = overshoot
      end

      # Returns true if sending should be suppressed (all-or-none).
      #
      def rate_limit_batch!(count)
        return false if count == 0
        return false if no_limit?

        case @overshoot
        when :soft_cap
          soft_cap_batch!(count)
        when :hard_cap
          hard_cap_batch!(count)
        end
      end

      private

      attr_reader :root_namespace, :hourly_bucket, :daily_bucket, :feature_flag, :log_message, :log_context

      # Suppress only when a window is ALREADY exhausted, then send and charge
      # the batch. A batch larger than the window therefore goes through once
      # and exhausts the window, rather than being suppressed forever because
      # it can never fit. This is a soft cap: a batch can overshoot the limit
      # within a window, which is acceptable for abuse mitigation.
      #
      # peek reads each counter without incrementing; the charge then adds the
      # whole batch in a single call (cost: count), so a 750-recipient push is
      # at most four Redis calls, not 1,500.
      #
      def soft_cap_batch!(count)
        exceeded_hourly = already_exceeded?(hourly_bucket, hourly_limit)
        exceeded_daily = already_exceeded?(daily_bucket, daily_limit)

        if exceeded_hourly || exceeded_daily
          log_rate_limited(count, exceeded_hourly: exceeded_hourly, exceeded_daily: exceeded_daily)

          return true
        end

        charge(hourly_bucket, hourly_limit, count)
        charge(daily_bucket, daily_limit, count)

        false
      end

      # Charge the whole batch up front and suppress the batch that trips either
      # window, matching Service Desk's original strict contract: with an hourly
      # limit of 1, a batch of 2 is suppressed all-or-none. The counter is still
      # charged, so later batches in the same window stay suppressed. A batch
      # larger than the window can never fit, which is intentional for this mode.
      #
      def hard_cap_batch!(count)
        exceeded_hourly = charge(hourly_bucket, hourly_limit, count)
        exceeded_daily = charge(daily_bucket, daily_limit, count)

        return false unless exceeded_hourly || exceeded_daily

        log_rate_limited(count, exceeded_hourly: exceeded_hourly, exceeded_daily: exceeded_daily)

        true
      end

      def already_exceeded?(limit_name, threshold)
        return false if threshold == NO_LIMIT

        ::Gitlab::ApplicationRateLimiter.peek(
          limit_name,
          scope: { namespace: root_namespace },
          threshold: threshold
        )
      end

      # Returns true when charging this batch trips the window. The :soft_cap
      # path ignores the return value; the :hard_cap path uses it to decide
      # whether to suppress the batch.
      #
      def charge(limit_name, threshold, count)
        return false if threshold == NO_LIMIT

        ::Gitlab::ApplicationRateLimiter.throttled?(
          limit_name,
          scope: { namespace: root_namespace },
          threshold: threshold,
          cost: count
        )
      end

      # Logged once per suppressed batch, not per email, and carries the root
      # namespace id because the Prometheus counters have no namespace label, so
      # only the log identifies who hit the limit.
      #
      def log_rate_limited(count, exceeded_hourly:, exceeded_daily:)
        windows = []
        windows << 'hourly' if exceeded_hourly
        windows << 'daily' if exceeded_daily

        logger.warn(
          build_structured_payload_labkit(
            **log_context,
            Labkit::Fields::LOG_MESSAGE => log_message,
            Labkit::Fields::GL_ROOT_NAMESPACE_ID => root_namespace.id,
            # Folded into one string: these have no dedicated standard fields and
            # carry no user input to sanitize.
            #
            Labkit::Fields::ADDITIONAL_DETAILS =>
              "exceeded_windows: '#{windows.join(',')}', suppressed_email_count: #{count}, " \
              "hourly_limit: #{hourly_limit}, daily_limit: #{daily_limit}"
          )
        )
      end

      def logger
        @logger ||= ::Gitlab::AppJsonLogger.build
      end

      # Flag checked before the limits so a namespace outside the rollout never
      # touches Redis.
      #
      def no_limit?
        return true unless Feature.enabled?(feature_flag, root_namespace, type: :wip) # rubocop:disable Gitlab/FeatureFlagKeyDynamic -- flag name is injected per feature; each caller passes a literal symbol

        hourly_limit == NO_LIMIT && daily_limit == NO_LIMIT
      end

      def hourly_limit
        root_namespace.actual_limits.limit_for(HOURLY_THRESHOLD_LIMIT_NAME) || NO_LIMIT
      end
      strong_memoize_attr :hourly_limit

      def daily_limit
        root_namespace.actual_limits.limit_for(DAILY_THRESHOLD_LIMIT_NAME) || NO_LIMIT
      end
      strong_memoize_attr :daily_limit
    end
  end
end

# frozen_string_literal: true

module ServiceDesk
  class EmailRateLimiter
    include Gitlab::Utils::StrongMemoize
    include ::Gitlab::Loggable

    HOURLY_LIMIT_NAME = :service_desk_outbound_emails_per_hour
    DAILY_LIMIT_NAME = :service_desk_outbound_emails_per_day
    NO_LIMIT = 0

    def initialize(project)
      @project = project
    end

    # Increments both window counters once per email in the batch, doing up
    # to 2 Redis checks per email. Callers must keep batches bounded (today,
    # the largest is IssueEmailParticipants::CreateService::MAX_NUMBER_OF_RECORDS);
    # this method has no internal cap.
    # Returns true if sending should be suppressed (all-or-none).
    def rate_limit_batch!(count)
      return false if no_limit?
      return false if count == 0

      # Both windows are charged for every email, with no short-circuit, so
      # neither counter lags behind the other once one is exhausted.
      results = Array.new(count) do
        [throttled?(HOURLY_LIMIT_NAME, hourly_limit), throttled?(DAILY_LIMIT_NAME, daily_limit)]
      end

      exceeded_hourly = results.any?(&:first)
      exceeded_daily = results.any?(&:last)

      return false unless exceeded_hourly || exceeded_daily

      log_rate_limited(count, exceeded_hourly: exceeded_hourly, exceeded_daily: exceeded_daily)

      true
    end

    def post_suppression_notice(work_item)
      # Notes::CreateService downgrades `internal: true` to a public note
      # instead of erroring when the author lacks :mark_note_as_internal,
      # and the support bot lacks it whenever Service Desk is disabled for
      # the project. A public notice would be visible to external
      # participants, so don't create a note at all in that case.
      return unless can_post_internal_note?(work_item)
      return if suppression_notice_throttled?(work_item)

      ::Notes::CreateService.new(
        project,
        support_bot,
        noteable: work_item,
        note: suppression_notice_text,
        internal: true
      ).execute
    end

    private

    attr_reader :project

    def throttled?(limit_name, threshold)
      return false if threshold == NO_LIMIT

      ::Gitlab::ApplicationRateLimiter.throttled?(
        limit_name,
        scope: { namespace: root_namespace },
        threshold: threshold
      )
    end

    # Logged once per suppressed batch, not once per email, so a comment
    # notifying several participants stays a single event. Attribution is the
    # point: the Prometheus rule counters already report how often limits are
    # hit, but carry no namespace label, so only the log identifies who. Note
    # this also outlives the internal suppression note, which is lost when the
    # work item is deleted.
    def log_rate_limited(count, exceeded_hourly:, exceeded_daily:)
      windows = []
      windows << 'hourly' if exceeded_hourly
      windows << 'daily' if exceeded_daily

      logger.warn(
        build_structured_payload_labkit(
          Labkit::Fields::LOG_MESSAGE => 'Service Desk outbound email rate limit exceeded',
          Labkit::Fields::GL_NAMESPACE_ID => project.namespace_id,
          Labkit::Fields::GL_ROOT_NAMESPACE_ID => root_namespace.id,
          Labkit::Fields::GL_PROJECT_ID => project.id,
          # Folded into one string because these have no dedicated standard
          # fields. Every value is an integer or a fixed label, so there is no
          # user input to sanitize here.
          Labkit::Fields::ADDITIONAL_DETAILS =>
            "exceeded_windows: '#{windows.join(',')}', suppressed_email_count: #{count}, " \
            "hourly_limit: #{hourly_limit}, daily_limit: #{daily_limit}"
        )
      )
    end

    def logger
      @logger ||= ::Gitlab::AppJsonLogger.build
    end

    def can_post_internal_note?(work_item)
      note = ::Note.new(project: project, noteable: work_item, author: support_bot)

      support_bot.can?(:mark_note_as_internal, note)
    end

    def suppression_notice_throttled?(work_item)
      ::Gitlab::ApplicationRateLimiter.throttled?(
        :service_desk_suppression_notice,
        scope: { work_item: work_item.id }
      )
    end

    def suppression_notice_text
      s_(
        'ServiceDesk|GitLab has not sent Service Desk emails for recent activity on this ' \
          'ticket because the namespace exceeded its Service Desk email rate limit. ' \
          'Emails resume automatically when the rate falls below the limit.'
      )
    end

    # The flag is the enforcement gate: rolling it out per root namespace
    # allows a gradual percentage-of-actors rollout, and it is removed once
    # enforcement is fully live (plan_limits values remain the permanent,
    # runtime-tunable control). Checked before the limits so a namespace
    # outside the rollout never touches Redis.
    def no_limit?
      return true unless Feature.enabled?(:service_desk_email_rate_limit, root_namespace, type: :wip)

      hourly_limit == NO_LIMIT && daily_limit == NO_LIMIT
    end

    def hourly_limit
      root_namespace.actual_limits.limit_for(HOURLY_LIMIT_NAME) || NO_LIMIT
    end
    strong_memoize_attr :hourly_limit

    def daily_limit
      root_namespace.actual_limits.limit_for(DAILY_LIMIT_NAME) || NO_LIMIT
    end
    strong_memoize_attr :daily_limit

    def root_namespace
      project.root_namespace
    end
    strong_memoize_attr :root_namespace

    def support_bot
      Users::Internal.in_organization(project.organization_id).support_bot
    end
    strong_memoize_attr :support_bot
  end
end

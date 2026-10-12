# frozen_string_literal: true

module ServiceDesk
  class EmailRateLimiter
    include Gitlab::Utils::StrongMemoize

    HOURLY_LIMIT_NAME = ::Gitlab::Email::NamespaceRateLimiter::HOURLY_THRESHOLD_LIMIT_NAME
    DAILY_LIMIT_NAME = ::Gitlab::Email::NamespaceRateLimiter::DAILY_THRESHOLD_LIMIT_NAME
    SERVICE_DESK_EMAIL_RATE_LIMIT_FEATURE_FLAG = :service_desk_email_rate_limit

    def initialize(project)
      @project = project
    end

    def rate_limit_batch!(count)
      limiter.rate_limit_batch!(count)
    end

    def post_suppression_notice(work_item)
      # Notes::CreateService downgrades `internal: true` to a public note
      # instead of erroring when the author lacks :mark_note_as_internal,
      # and the support bot lacks it whenever Service Desk is disabled for
      # the project. A public notice would be visible to external
      # participants, so don't create a note at all in that case.
      #
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

    def limiter
      ::Gitlab::Email::NamespaceRateLimiter.new(
        root_namespace: project.root_namespace,
        hourly_bucket: HOURLY_LIMIT_NAME,
        daily_bucket: DAILY_LIMIT_NAME,
        feature_flag: SERVICE_DESK_EMAIL_RATE_LIMIT_FEATURE_FLAG,
        log_message: 'Service Desk outbound email rate limit exceeded',
        log_context: {
          Labkit::Fields::CLASS_NAME => self.class.name,
          Labkit::Fields::GL_NAMESPACE_ID => project.namespace_id,
          Labkit::Fields::GL_PROJECT_ID => project.id
        },
        # Service Desk suppresses the batch that trips the window (hard cap),
        # unlike the new large-recipient features which allow one overshoot.
        #
        overshoot: :hard_cap
      )
    end
    strong_memoize_attr :limiter

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

    def support_bot
      Users::Internal.in_organization(project.organization_id).support_bot
    end
    strong_memoize_attr :support_bot
  end
end

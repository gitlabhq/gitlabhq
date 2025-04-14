# frozen_string_literal: true

module WebHooks
  module AutoDisabling
    extend ActiveSupport::Concern
    include ::Gitlab::Loggable

    ENABLED_HOOK_TYPES = %w[ProjectHook].freeze

    TEMPORARILY_DISABLED_FAILURE_THRESHOLD = 3
    # A webhook will be failing and being temporarily disabled for the max backoff of 1 day (`MAX_BACKOFF`)
    # for at least 1 month before it becomes permanently disabled on its 40th failure.
    # Exactly how quickly this happens depends on how frequently it triggers.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/503733#note_2217234805
    PERMANENTLY_DISABLED_FAILURE_THRESHOLD = 39

    INITIAL_BACKOFF = 1.minute.freeze
    MAX_BACKOFF = 1.day.freeze
    BACKOFF_GROWTH_FACTOR = 2.0

    class_methods do
      def auto_disabling_enabled?
        enabled_hook_types.include?(name) &&
          Gitlab::SafeRequestStore.fetch(:auto_disabling_web_hooks) do
            Feature.enabled?(:auto_disabling_web_hooks, type: :ops)
          end
      end

      private

      def enabled_hook_types
        ENABLED_HOOK_TYPES
      end
    end

    included do
      delegate :auto_disabling_enabled?, to: :class, private: true

      ignore_column :backoff_count, remove_with: '18.1', remove_after: '2025-05-20'

      # A webhook is disabled if:
      #
      # - it has exceeded the grace TEMPORARILY_DISABLED_FAILURE_THRESHOLD (recent_failures > ?)
      #   - AND the time period it was disabled for has not yet expired (disabled_until >= ?)
      # - OR it has reached the PERMANENTLY_DISABLED_FAILURE_THRESHOLD (recent_failures > ?)
      scope :disabled, -> do
        return all if Gitlab::SilentMode.enabled?
        return none unless auto_disabling_enabled?

        where(
          '(recent_failures > ? AND (disabled_until IS NULL OR disabled_until >= ?)) OR recent_failures > ?',
          TEMPORARILY_DISABLED_FAILURE_THRESHOLD,
          Time.current,
          PERMANENTLY_DISABLED_FAILURE_THRESHOLD
        )
      end

      # A webhook is executable if:
      #
      # - it has not exceeeded the grace TEMPORARILY_DISABLED_FAILURE_THRESHOLD (recent_failures <= ?)
      # - OR it has exceeded the grace TEMPORARILY_DISABLED_FAILURE_THRESHOLD and:
      #   - it was temporarily disabled but can now be triggered again (disabled_until < ?)
      #   - AND has not reached the PERMANENTLY_DISABLED_FAILURE_THRESHOLD (recent_failures <= ?)
      scope :executable, -> do
        return none if Gitlab::SilentMode.enabled?
        return all unless auto_disabling_enabled?

        where(
          '(recent_failures <= ? OR (recent_failures > ? AND disabled_until IS NOT NULL AND disabled_until < ?)) ' \
            'AND recent_failures <= ?',
          TEMPORARILY_DISABLED_FAILURE_THRESHOLD,
          TEMPORARILY_DISABLED_FAILURE_THRESHOLD,
          Time.current,
          PERMANENTLY_DISABLED_FAILURE_THRESHOLD
        )
      end
    end

    def executable?
      return true unless auto_disabling_enabled?

      !temporarily_disabled? && !permanently_disabled?
    end

    def temporarily_disabled?
      return false unless auto_disabling_enabled?

      disabled_until.present? && disabled_until >= Time.current &&
        recent_failures.between?(TEMPORARILY_DISABLED_FAILURE_THRESHOLD + 1, PERMANENTLY_DISABLED_FAILURE_THRESHOLD)
    end

    def permanently_disabled?
      return false unless auto_disabling_enabled?

      recent_failures > PERMANENTLY_DISABLED_FAILURE_THRESHOLD ||
        # Keep the old definition of permanently disabled just until we have migrated all records to the new definition
        # with `MigrateOldDisabledWebHookToNewState`
        # TODO Remove the next line as part of https://gitlab.com/gitlab-org/gitlab/-/issues/525446
        (recent_failures > TEMPORARILY_DISABLED_FAILURE_THRESHOLD && disabled_until.blank?)
    end

    def enable!
      return unless auto_disabling_enabled?
      return if recent_failures == 0 && disabled_until.nil?

      attrs = { recent_failures: 0, disabled_until: nil }

      assign_attributes(attrs)
      logger.info(hook_id: id, action: 'enable', **attrs)
      save(validate: false)
    end

    # Don't actually back-off until a grace level of TEMPORARILY_DISABLED_FAILURE_THRESHOLD failures have been seen
    # tracked in the recent_failures counter
    def backoff!
      return unless executable?

      new_recent_failures = next_failure_count

      attrs = { recent_failures: new_recent_failures }
      attrs[:disabled_until] = next_backoff.from_now if new_recent_failures > TEMPORARILY_DISABLED_FAILURE_THRESHOLD

      assign_attributes(attrs)

      return unless changed?

      logger.info(hook_id: id, action: 'backoff', **attrs)
      save(validate: false)
    end

    def alert_status
      return :executable unless auto_disabling_enabled?

      if temporarily_disabled?
        :temporarily_disabled
      elsif permanently_disabled?
        :disabled
      else
        :executable
      end
    end

    private

    def logger
      @logger ||= Gitlab::WebHooks::Logger.build
    end

    def next_failure_count
      recent_failures.succ.clamp(1, PERMANENTLY_DISABLED_FAILURE_THRESHOLD + 1)
    end

    def next_backoff
      backoff_count = recent_failures - TEMPORARILY_DISABLED_FAILURE_THRESHOLD

      (INITIAL_BACKOFF * (BACKOFF_GROWTH_FACTOR**backoff_count))
        .clamp(INITIAL_BACKOFF, MAX_BACKOFF)
        .seconds
    end
  end
end

WebHooks::AutoDisabling.prepend_mod
WebHooks::AutoDisabling::ClassMethods.prepend_mod

# frozen_string_literal: true

module WebHooks
  module AutoDisabling
    extend ActiveSupport::Concern
    include ::Gitlab::Loggable

    ENABLED_HOOK_TYPES = %w[ProjectHook].freeze
    MAX_FAILURES = 100
    FAILURE_THRESHOLD = 3
    EXCEEDED_FAILURE_THRESHOLD = FAILURE_THRESHOLD + 1
    INITIAL_BACKOFF = 1.minute.freeze
    MAX_BACKOFF = 1.day.freeze
    MAX_BACKOFF_COUNT = 11
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

      # A hook is disabled if:
      #
      # - we have exceeded the grace FAILURE_THRESHOLD (recent_failures > ?)
      # - and either:
      #   - disabled_until is nil (i.e. this was set by WebHook#fail!)
      #   - or disabled_until is in the future (i.e. this was set by WebHook#backoff!)
      # - OR silent mode is enabled.
      scope :disabled, -> do
        return all if Gitlab::SilentMode.enabled?
        return none unless auto_disabling_enabled?

        where(
          'recent_failures > ? AND (disabled_until IS NULL OR disabled_until >= ?)',
          FAILURE_THRESHOLD,
          Time.current
        )
      end

      # A hook is executable if:
      #
      # - we have not yet exceeeded the grace FAILURE_THRESHOLD (recent_failures <= ?)
      # - OR we have exceeded the grace FAILURE_THRESHOLD and neither of the following is true:
      #   - disabled_until is nil (i.e. this was set by WebHook#fail!)
      #   - disabled_until is in the future (i.e. this was set by WebHook#backoff!)
      # - AND silent mode is not enabled.
      scope :executable, -> do
        return none if Gitlab::SilentMode.enabled?
        return all unless auto_disabling_enabled?

        where(
          'recent_failures <= ? OR (recent_failures > ? AND (disabled_until IS NOT NULL) AND (disabled_until < ?))',
          FAILURE_THRESHOLD,
          FAILURE_THRESHOLD,
          Time.current
        )
      end
    end

    def executable?
      return true unless auto_disabling_enabled?

      !temporarily_disabled? && !permanently_disabled?
    end

    def temporarily_disabled?
      return false unless auto_disabling_enabled?

      disabled_until.present? && disabled_until >= Time.current && recent_failures > FAILURE_THRESHOLD
    end

    def permanently_disabled?
      return false unless auto_disabling_enabled?

      recent_failures > FAILURE_THRESHOLD && disabled_until.blank?
    end

    def enable!
      return unless auto_disabling_enabled?
      return if recent_failures == 0 && disabled_until.nil? && backoff_count == 0

      attrs = { recent_failures: 0, disabled_until: nil, backoff_count: 0 }

      assign_attributes(attrs)
      logger.info(hook_id: id, action: 'enable', **attrs)
      save(validate: false)
    end

    # Don't actually back-off until a grace level of FAILURE_THRESHOLD failures have been seen
    # tracked in the recent_failures counter
    def backoff!
      return unless auto_disabling_enabled?
      return if permanently_disabled? || temporarily_disabled?

      attrs = { recent_failures: next_failure_count }

      if recent_failures >= FAILURE_THRESHOLD
        attrs[:backoff_count] = next_backoff_count
        attrs[:disabled_until] = next_backoff.from_now
      end

      assign_attributes(attrs)

      return unless changed?

      logger.info(hook_id: id, action: 'backoff', **attrs)
      save(validate: false)
    end

    def failed!
      return unless auto_disabling_enabled?
      return unless recent_failures < MAX_FAILURES

      attrs = { disabled_until: nil, backoff_count: 0, recent_failures: next_failure_count }

      assign_attributes(**attrs)
      logger.info(hook_id: id, action: 'disable', **attrs)
      save(validate: false)
    end

    def next_backoff
      # Optimization to prevent expensive exponentiation and possible overflows
      return MAX_BACKOFF if backoff_count >= MAX_BACKOFF_COUNT

      (INITIAL_BACKOFF * (BACKOFF_GROWTH_FACTOR**backoff_count))
        .clamp(INITIAL_BACKOFF, MAX_BACKOFF)
        .seconds
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
      recent_failures.succ.clamp(1, MAX_FAILURES)
    end

    def next_backoff_count
      backoff_count.succ.clamp(1, MAX_FAILURES)
    end
  end
end

WebHooks::AutoDisabling.prepend_mod
WebHooks::AutoDisabling::ClassMethods.prepend_mod

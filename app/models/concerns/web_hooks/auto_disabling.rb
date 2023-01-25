# frozen_string_literal: true

module WebHooks
  module AutoDisabling
    extend ActiveSupport::Concern

    included do
      # A hook is disabled if:
      #
      # - we are no longer in the grace-perod (recent_failures > ?)
      # - and either:
      #   - disabled_until is nil (i.e. this was set by WebHook#fail!)
      #   - or disabled_until is in the future (i.e. this was set by WebHook#backoff!)
      scope :disabled, -> do
        where('recent_failures > ? AND (disabled_until IS NULL OR disabled_until >= ?)',
              WebHook::FAILURE_THRESHOLD, Time.current)
      end

      # A hook is executable if:
      #
      # - we are still in the grace-period (recent_failures <= ?)
      # - OR we have exceeded the grace period and neither of the following is true:
      #   - disabled_until is nil (i.e. this was set by WebHook#fail!)
      #   - disabled_until is in the future (i.e. this was set by WebHook#backoff!)
      scope :executable, -> do
        where('recent_failures <= ? OR (recent_failures > ? AND (disabled_until IS NOT NULL) AND (disabled_until < ?))',
              WebHook::FAILURE_THRESHOLD, WebHook::FAILURE_THRESHOLD, Time.current)
      end
    end

    def executable?
      !temporarily_disabled? && !permanently_disabled?
    end

    def temporarily_disabled?
      return false if recent_failures <= WebHook::FAILURE_THRESHOLD

      disabled_until.present? && disabled_until >= Time.current
    end

    def permanently_disabled?
      return false if disabled_until.present?

      recent_failures > WebHook::FAILURE_THRESHOLD
    end

    def disable!
      return if permanently_disabled?

      super
    end

    def backoff!
      return if permanently_disabled? || (backoff_count >= WebHook::MAX_FAILURES && temporarily_disabled?)

      super
    end

    def alert_status
      if temporarily_disabled?
        :temporarily_disabled
      elsif permanently_disabled?
        :disabled
      else
        :executable
      end
    end
  end
end

module EE
  # Namespace EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Namespace` model
  module Namespace
    extend ActiveSupport::Concern

    prepended do
      has_one :namespace_statistics, dependent: :destroy

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :namespace_statistics, allow_nil: true
    end

    def actual_shared_runners_minutes_limit
      shared_runners_minutes_limit ||
        current_application_settings.shared_runners_minutes
    end

    def shared_runners_minutes_limit_enabled?
      shared_runners_enabled? &&
        actual_shared_runners_minutes_limit.nonzero?
    end

    def shared_runners_minutes_used?
      shared_runners_minutes_limit_enabled? &&
        shared_runners_minutes.to_i >= actual_shared_runners_minutes_limit
    end
  end
end

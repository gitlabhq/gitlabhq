module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Project` model
  module Project
    extend ActiveSupport::Concern

    included do
      delegate :shared_runners_minutes, :shared_runners_minutes_last_reset,
        to: :project_metrics, allow_nil: true

      delegate :actual_shared_runners_minutes_limit,
        :shared_runners_minutes_used?, to: :namespace

      has_one :project_metrics, dependent: :destroy
    end

    def shared_runners_minutes_limit_enabled?
      !public? && shared_runners_enabled? && namespace.shared_runners_minutes_limit_enabled?
    end

    def shared_runners
      if shared_runners_enabled? && !namespace.shared_runners_minutes_used?
        Ci::Runner.shared
      else
        Ci::Runner.none
      end
    end
  end
end

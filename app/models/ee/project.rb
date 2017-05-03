module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Project` model
  module Project
    extend ActiveSupport::Concern

    prepended do
      scope :with_shared_runners_limit_enabled, -> { with_shared_runners.non_public_only }

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :statistics, allow_nil: true

      delegate :actual_shared_runners_minutes_limit,
        :shared_runners_minutes_used?, to: :namespace
    end

    def shared_runners_available?
      super && !namespace.shared_runners_minutes_used?
    end

    def shared_runners_minutes_limit_enabled?
      !public? && shared_runners_enabled? && namespace.shared_runners_minutes_limit_enabled?
    end

    def service_desk_address
      return nil unless service_desk_available?

      config = ::Gitlab.config.incoming_email
      wildcard = ::Gitlab::IncomingEmail::WILDCARD_PLACEHOLDER

      config.address&.gsub(wildcard, full_path)
    end

    private

    def service_desk_available?
      return @service_desk_available if defined?(@service_desk_available)

      @service_desk_available = EE::Gitlab::ServiceDesk.enabled? && service_desk_enabled?
    end
  end
end

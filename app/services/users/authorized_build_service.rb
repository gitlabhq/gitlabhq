# frozen_string_literal: true

module Users
  class AuthorizedBuildService < BuildService
    extend ::Gitlab::Utils::Override

    private

    override :validate_access!
    def validate_access!
      # no-op
    end

    def signup_params
      super + [:skip_confirmation]
    end
  end
end

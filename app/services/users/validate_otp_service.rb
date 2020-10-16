# frozen_string_literal: true

module Users
  class ValidateOtpService < BaseService
    def initialize(current_user)
      @current_user = current_user
      @strategy = if Feature.enabled?(:forti_authenticator, current_user)
                    ::Gitlab::Auth::Otp::Strategies::FortiAuthenticator.new(current_user)
                  else
                    ::Gitlab::Auth::Otp::Strategies::Devise.new(current_user)
                  end
    end

    def execute(otp_code)
      strategy.validate(otp_code)
    rescue StandardError => ex
      Gitlab::ErrorTracking.log_exception(ex)
      error(message: ex.message)
    end

    private

    attr_reader :strategy
  end
end

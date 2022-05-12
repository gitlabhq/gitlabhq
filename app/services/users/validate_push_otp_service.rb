# frozen_string_literal: true

module Users
  class ValidatePushOtpService < BaseService
    include ::Gitlab::Auth::Otp::Fortinet

    def initialize(current_user)
      @current_user = current_user
      @strategy = if forti_authenticator_enabled?(current_user)
                    ::Gitlab::Auth::Otp::Strategies::FortiAuthenticator::PushOtp.new(current_user)
                  end
    end

    def execute
      strategy.validate
    rescue StandardError => ex
      Gitlab::ErrorTracking.log_exception(ex)
      error(ex.message)
    end

    private

    attr_reader :strategy
  end
end

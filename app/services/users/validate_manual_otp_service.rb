# frozen_string_literal: true

module Users
  class ValidateManualOtpService < BaseService
    include ::Gitlab::Auth::Otp::Fortinet
    include ::Gitlab::Auth::Otp::DuoAuth

    def initialize(current_user)
      @current_user = current_user
      @strategy = if forti_authenticator_enabled?(current_user)
                    ::Gitlab::Auth::Otp::Strategies::FortiAuthenticator::ManualOtp.new(current_user)
                  elsif forti_token_cloud_enabled?(current_user)
                    ::Gitlab::Auth::Otp::Strategies::FortiTokenCloud.new(current_user)
                  elsif duo_auth_enabled?(current_user)
                    ::Gitlab::Auth::Otp::Strategies::DuoAuth::ManualOtp.new(current_user)
                  else
                    ::Gitlab::Auth::Otp::Strategies::Devise.new(current_user)
                  end
    end

    def execute(otp_code)
      strategy.validate(otp_code)
    rescue StandardError => ex
      Gitlab::ErrorTracking.log_exception(ex)
      error(ex.message)
    end

    private

    attr_reader :strategy
  end
end

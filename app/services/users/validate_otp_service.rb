# frozen_string_literal: true

module Users
  class ValidateOtpService < BaseService
    include ::Gitlab::Auth::Otp::Fortinet

    def initialize(current_user)
      @current_user = current_user
      @strategy = if forti_authenticator_enabled?(current_user)
                    ::Gitlab::Auth::Otp::Strategies::FortiAuthenticator.new(current_user)
                  elsif forti_token_cloud_enabled?(current_user)
                    ::Gitlab::Auth::Otp::Strategies::FortiTokenCloud.new(current_user)
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

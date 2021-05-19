# frozen_string_literal: true

module Users
  class UpsertCreditCardValidationService < BaseService
    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def execute
      ::Users::CreditCardValidation.upsert(@params)

      ServiceResponse.success(message: 'CreditCardValidation was set')
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::NotNullViolation => e
      ServiceResponse.error(message: "Could not set CreditCardValidation: #{e.message}")
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, params: @params, class: self.class.to_s)
      ServiceResponse.error(message: "Could not set CreditCardValidation: #{e.message}")
    end
  end
end

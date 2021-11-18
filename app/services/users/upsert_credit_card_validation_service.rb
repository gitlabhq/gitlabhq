# frozen_string_literal: true

module Users
  class UpsertCreditCardValidationService < BaseService
    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def execute
      @params = {
        user_id: params.fetch(:user_id),
        credit_card_validated_at: params.fetch(:credit_card_validated_at),
        expiration_date: get_expiration_date(params),
        last_digits: Integer(params.fetch(:credit_card_mask_number), 10),
        network: params.fetch(:credit_card_type),
        holder_name: params.fetch(:credit_card_holder_name)
      }

      ::Users::CreditCardValidation.upsert(@params)

      ServiceResponse.success(message: 'CreditCardValidation was set')
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::NotNullViolation => e
      ServiceResponse.error(message: "Could not set CreditCardValidation: #{e.message}")
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, params: @params, class: self.class.to_s)
      ServiceResponse.error(message: "Could not set CreditCardValidation: #{e.message}")
    end

    private

    def get_expiration_date(params)
      year = params.fetch(:credit_card_expiration_year)
      month = params.fetch(:credit_card_expiration_month)

      Date.new(year, month, -1) # last day of the month
    end
  end
end

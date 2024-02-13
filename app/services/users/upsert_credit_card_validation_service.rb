# frozen_string_literal: true

module Users
  class UpsertCreditCardValidationService < BaseService
    attr_reader :params

    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def execute
      credit_card = Users::CreditCardValidation.find_or_initialize_by_user(user_id)

      credit_card_params = {
        credit_card_validated_at: credit_card_validated_at,
        last_digits: last_digits,
        holder_name: holder_name,
        network: network,
        expiration_date: expiration_date,
        zuora_payment_method_xid: zuora_payment_method_xid
      }

      credit_card.update!(credit_card_params)

      success
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::NotNullViolation, ActiveRecord::RecordInvalid
      error
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
      error
    end

    private

    def user_id
      params.fetch(:user_id)
    end

    def credit_card_validated_at
      params.fetch(:credit_card_validated_at)
    end

    def last_digits
      Integer(params.fetch(:credit_card_mask_number), 10)
    end

    def holder_name
      params.fetch(:credit_card_holder_name)
    end

    def network
      params.fetch(:credit_card_type)
    end

    def zuora_payment_method_xid
      params[:zuora_payment_method_xid]
    end

    def expiration_date
      year = params.fetch(:credit_card_expiration_year)
      month = params.fetch(:credit_card_expiration_month)

      Date.new(year, month, -1) # last day of the month
    end

    def success
      ServiceResponse.success(message: _('Credit card validation record saved'))
    end

    def error
      ServiceResponse.error(message: _('Error saving credit card validation record'))
    end
  end
end

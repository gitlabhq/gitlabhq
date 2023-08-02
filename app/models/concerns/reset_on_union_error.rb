# frozen_string_literal: true

module ResetOnUnionError
  extend ActiveSupport::Concern

  MAX_RESET_PERIOD = 10.minutes

  included do |base|
    base.rescue_from ActiveRecord::StatementInvalid, with: :reset_on_union_error

    base.class_attribute :previous_reset_columns_from_error
  end

  class_methods do
    def reset_on_union_error(exception)
      if reset_on_statement_invalid?(exception)
        class_to_be_reset = base_class

        class_to_be_reset.reset_column_information
        Gitlab::ErrorTracking.log_exception(exception, { reset_model_name: class_to_be_reset.name })

        class_to_be_reset.previous_reset_columns_from_error = Time.current
      end

      raise
    end

    def reset_on_statement_invalid?(exception)
      return false unless exception.message.include?("each UNION query must have the same number of columns")

      return false if base_class.previous_reset_columns_from_error? &&
        base_class.previous_reset_columns_from_error > MAX_RESET_PERIOD.ago

      Feature.enabled?(:reset_column_information_on_statement_invalid, type: :ops)
    end
  end
end

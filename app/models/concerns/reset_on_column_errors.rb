# frozen_string_literal: true

module ResetOnColumnErrors
  extend ActiveSupport::Concern

  MAX_RESET_PERIOD = 10.minutes

  included do |base|
    base.rescue_from ActiveRecord::StatementInvalid, with: :reset_on_union_error
    base.rescue_from ActiveModel::UnknownAttributeError, with: :reset_on_unknown_attribute_error

    base.class_attribute :previous_reset_columns_from_error
  end

  class_methods do
    def do_reset(exception)
      class_to_be_reset = base_class

      class_to_be_reset.reset_column_information
      Gitlab::ErrorTracking.log_exception(exception, { reset_model_name: class_to_be_reset.name })

      class_to_be_reset.previous_reset_columns_from_error = Time.current
    end

    def reset_on_union_error(exception)
      if exception.message.include?("each UNION query must have the same number of columns") && should_reset?
        do_reset(exception)
      end

      raise
    end

    def should_reset?
      return false if base_class.previous_reset_columns_from_error? &&
        base_class.previous_reset_columns_from_error > MAX_RESET_PERIOD.ago

      Feature.enabled?(:reset_column_information_on_statement_invalid, type: :ops)
    end
  end

  def reset_on_union_error(exception)
    self.class.reset_on_union_error(exception)
  end

  def reset_on_unknown_attribute_error(exception)
    self.class.do_reset(exception) if self.class.should_reset?

    raise
  end
end

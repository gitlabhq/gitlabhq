# frozen_string_literal: true

module ActiveRecordRelationUnionReset
  MAX_RESET_PERIOD = 10.minutes

  def exec_queries
    super
  rescue ActiveRecord::StatementInvalid => e
    if reset_on_statement_invalid?(e)
      class_to_be_reset = klass.base_class

      class_to_be_reset.reset_column_information
      Gitlab::ErrorTracking.log_exception(e, { reset_model_name: class_to_be_reset.name })

      class_to_be_reset.previous_reset_columns_from_error = Time.now
    end

    raise
  end

  private

  def reset_on_statement_invalid?(exception)
    return false unless exception.message.include?("each UNION query must have the same number of columns")

    return false if klass.base_class.previous_reset_columns_from_error? &&
      klass.base_class.previous_reset_columns_from_error > MAX_RESET_PERIOD.ago

    Feature.enabled?(:reset_column_information_on_statement_invalid, type: :ops)
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.class_attribute :previous_reset_columns_from_error
  ActiveRecord::Relation.prepend(ActiveRecordRelationUnionReset)
end

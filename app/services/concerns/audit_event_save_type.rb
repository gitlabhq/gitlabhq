# frozen_string_literal: true

module AuditEventSaveType
  SAVE_TYPES = {
    database: 0b01,
    stream: 0b10,
    database_and_stream: 0b11
  }.freeze

  # def should_save_stream?(type)
  # def should_save_database?(type)
  [:database, :stream].each do |type|
    define_method("should_save_#{type}?") do |param_type|
      return false unless save_type_valid?(param_type)

      # If the current type does not support query, the result of the `&` operation is 0 .
      SAVE_TYPES[param_type] & SAVE_TYPES[type] != 0
    end
  end

  private

  def save_type_valid?(type)
    SAVE_TYPES.key?(type)
  end
end

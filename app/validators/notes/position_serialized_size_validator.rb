# frozen_string_literal: true

module Notes
  class PositionSerializedSizeValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      max_bytesize = options.fetch(:max_bytesize)

      return unless record.new_record? || record.will_save_change_to_attribute?(attribute)

      return unless raw_value(value).bytesize > max_bytesize

      record.errors.add(attribute, "is too large (max #{max_bytesize} bytes)")
    end

    private

    def raw_value(value)
      value.is_a?(String) ? value : value.to_json
    end
  end
end

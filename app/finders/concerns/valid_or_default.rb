# frozen_string_literal: true

module ValidOrDefault
  def valid_or_default(value, valid_values, default)
    return value if valid_values.include?(value)

    default
  end
end

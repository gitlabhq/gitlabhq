# frozen_string_literal: true

module Types
  class VisibilityLevelsEnum < BaseEnum
    Gitlab::VisibilityLevel.string_options.each do |name, int_value|
      value name.downcase, value: int_value
    end
  end
end

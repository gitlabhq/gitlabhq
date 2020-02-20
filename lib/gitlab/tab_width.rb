# frozen_string_literal: true

module Gitlab
  module TabWidth
    extend self

    MIN = 1
    MAX = 12
    DEFAULT = 8

    def css_class_for_user(user)
      return css_class_for_value(DEFAULT) unless user

      css_class_for_value(user.tab_width)
    end

    private

    def css_class_for_value(value)
      raise ArgumentError unless in_range?(value)

      "tab-width-#{value}"
    end

    def in_range?(value)
      (MIN..MAX).cover?(value)
    end
  end
end

# frozen_string_literal: true

module Banzai
  module Filter
    # The maximum number of items that a filter should allow,
    # such as emojis, etc.
    FILTER_ITEM_LIMIT = 1000

    def self.[](name)
      const_get("#{name.to_s.camelize}Filter", false)
    end

    def self.filter_item_limit_exceeded?(count)
      count >= FILTER_ITEM_LIMIT
    end
  end
end

# frozen_string_literal: true

module UsageStatistics
  extend ActiveSupport::Concern

  class_methods do
    def distinct_count_by(column = nil, fallback = -1)
      distinct.count(column)
    rescue ActiveRecord::StatementInvalid
      fallback
    end
  end
end

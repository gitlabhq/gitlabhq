# frozen_string_literal: true

class IssuableSeverity < ApplicationRecord
  belongs_to :issue

  validates :issue, presence: true, uniqueness: true
  validates :severity, presence: true

  enum severity: {
    unknown: 0,
    low: 1,
    medium: 2,
    high: 3,
    critical: 4
  }
end

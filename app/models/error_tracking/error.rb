# frozen_string_literal: true

class ErrorTracking::Error < ApplicationRecord
  belongs_to :project

  has_many :events, class_name: 'ErrorTracking::ErrorEvent'

  validates :project, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :actor, presence: true

  def self.report_error(name:, description:, actor:, platform:, timestamp:)
    safe_find_or_create_by(
      name: name,
      description: description,
      actor: actor,
      platform: platform
    ) do |error|
      error.update!(last_seen_at: timestamp)
    end
  end
end

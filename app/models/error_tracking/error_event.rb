# frozen_string_literal: true

class ErrorTracking::ErrorEvent < ApplicationRecord
  belongs_to :error

  validates :payload, json_schema: { filename: 'error_tracking_event_payload' }

  validates :error, presence: true
  validates :description, presence: true
  validates :occurred_at, presence: true
end

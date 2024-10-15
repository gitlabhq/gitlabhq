# frozen_string_literal: true

class ErrorTracking::ErrorEvent < ApplicationRecord
  belongs_to :error, counter_cache: :events_count

  # Scrub null bytes
  attribute :payload, Gitlab::Database::Type::JsonPgSafe.new

  validates :payload, json_schema: { filename: 'error_tracking_event_payload' }

  validates :error, presence: true
  validates :description, presence: true, length: { maximum: 1024 }
  validates :level, length: { maximum: 255 }
  validates :environment, length: { maximum: 255 }
  validates :occurred_at, presence: true

  def stacktrace
    @stacktrace ||= ErrorTracking::StacktraceBuilder.new(payload).stacktrace
  end

  # For compatibility with sentry integration
  def to_sentry_error_event
    Gitlab::ErrorTracking::ErrorEvent.new(
      issue_id: error_id,
      date_received: occurred_at,
      stack_trace_entries: stacktrace
    )
  end

  def release
    payload['release']
  end
end

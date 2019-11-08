# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_error_event, class: Gitlab::ErrorTracking::ErrorEvent do
    issue_id { 'id' }
    date_received { Time.now.iso8601 }
    stack_trace_entries do
      {
        'stacktrace' =>
          {
            'frames' => [{ 'file' => 'test.rb' }]
          }
      }
    end

    skip_create
  end
end

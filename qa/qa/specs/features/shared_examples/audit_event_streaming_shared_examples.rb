# frozen_string_literal: true

module QA
  RSpec.shared_examples 'streamed events' do |event_type, entity_type, testcase|
    it 'the external server receives the event', testcase: testcase do
      entity_path # Call to trigger the event before we can check it was received
      event_record = mock_service.wait_for_event(event_type, entity_type, entity_path)
      verify_response = mock_service.verify

      # Most of the verification is done via `wait_for_event` above
      # The other two are checks for data that couldn't be added to a mock in advance
      aggregate_failures do
        # Smocker treats header values as arrays
        # Secret tokens are auto-generated for HTTP destinations if not provided
        # https://docs.gitlab.com/ee/administration/audit_event_streaming/#verify-event-authenticity

        actual_headers = event_record[:headers].transform_keys(&:to_s)
        expected_headers = headers.transform_keys { |k| k.to_s.tr('_', '-') }
          .transform_values { |v| [v] }
          .merge("X-Gitlab-Event-Streaming-Token" => [stream_destination.secret_token])

        expect(actual_headers).to include(expected_headers)
        expect(event_record[:body]).to include(details: a_hash_including(target_details: target_details))
        expect(verify_response).to be_success,
          "Failures when verifying events received:\n#{JSON.pretty_generate(verify_response.failures)}"
      end
    end
  end
end

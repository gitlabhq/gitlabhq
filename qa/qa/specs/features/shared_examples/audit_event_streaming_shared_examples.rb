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
        # Verification tokens are created for us if we don't provide one
        # https://docs.gitlab.com/ee/administration/audit_event_streaming/#verify-event-authenticity
        expect(event_record[:headers]).to include(
          headers.transform_values { |v| [v] }
            .merge("X-Gitlab-Event-Streaming-Token": [stream_destination.verification_token])
        )
        expect(event_record[:body]).to include(details: a_hash_including(target_details: target_details))
        expect(verify_response).to be_success,
          "Failures when verifying events received:\n#{JSON.pretty_generate(verify_response.failures)}"
      end
    end
  end
end

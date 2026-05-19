# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/merge_requests/approved_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe MergeRequests::ApprovedEvent, feature_category: :code_review_workflow do
  it_behaves_like 'an event with schema',
    valid_data: { current_user_id: 1, merge_request_id: 2 },
    missing_required: %i[current_user_id merge_request_id],
    invalid_types: {
      current_user_id: 'not_an_integer',
      merge_request_id: 'not_an_integer',
      approved_at: 'not-a-date'
    }

  describe '#schema' do
    context 'with valid optional approved_at' do
      it 'accepts a date-time string' do
        data = { current_user_id: 1, merge_request_id: 2, approved_at: '2024-01-10T12:00:00Z' }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

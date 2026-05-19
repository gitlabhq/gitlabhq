# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/merge_requests/draft_note_published_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe MergeRequests::DraftNotePublishedEvent, feature_category: :code_review_workflow do
  it_behaves_like 'an event with schema',
    valid_data: { current_user_id: 1, merge_request_id: 2 },
    missing_required: %i[current_user_id merge_request_id],
    invalid_types: {
      current_user_id: 'not_an_integer',
      merge_request_id: 'not_an_integer',
      review_id: 'not_an_integer'
    }

  describe '#schema' do
    context 'with valid optional review_id' do
      it 'accepts an integer' do
        data = { current_user_id: 1, merge_request_id: 2, review_id: 3 }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

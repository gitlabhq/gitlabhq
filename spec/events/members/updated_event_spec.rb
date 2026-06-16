# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/members/updated_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Members::UpdatedEvent, feature_category: :seat_cost_management do
  it_behaves_like 'an event with schema',
    valid_data: { source_id: 1, source_type: 'Project', user_ids: [2, 3] },
    missing_required: %i[source_id source_type user_ids],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      user_ids: 'not_an_array'
    }

  describe '#schema' do
    context 'with invalid user_ids array items' do
      it 'raises an error when user_ids contains non-integers' do
        data = { source_id: 1, source_type: 'Project', user_ids: ['not_an_integer'] }

        expect { described_class.new(data: data) }
          .to raise_error(Gitlab::EventStore::InvalidEvent, /does not match/)
      end
    end
  end
end

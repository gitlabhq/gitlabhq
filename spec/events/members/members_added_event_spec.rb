# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/members/members_added_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Members::MembersAddedEvent, feature_category: :seat_cost_management do
  it_behaves_like 'an event with schema',
    valid_data: { source_id: 1, source_type: 'Project' },
    missing_required: %i[source_id source_type],
    invalid_types: { source_id: 'not_an_integer', invited_user_ids: ['not_an_integer'] }

  describe '#schema' do
    context 'with valid optional invited_user_ids' do
      it 'accepts an array of integers' do
        data = { source_id: 1, source_type: 'Project', invited_user_ids: [1, 2] }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

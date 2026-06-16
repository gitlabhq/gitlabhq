# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/members/destroyed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Members::DestroyedEvent, feature_category: :seat_cost_management do
  it_behaves_like 'an event with schema',
    valid_data: { source_id: 1, source_type: 'Project', user_id: 2 },
    missing_required: %i[source_id source_type user_id],
    invalid_types: {
      source_id: 'not_an_integer',
      source_type: 123,
      user_id: 'not_an_integer',
      root_namespace_id: 'not_an_integer'
    }

  describe '#schema' do
    let(:valid_data) { { source_id: 1, source_type: 'Project', user_id: 2 } }

    context 'with valid optional fields' do
      it 'accepts root_namespace_id' do
        data = valid_data.merge(root_namespace_id: 3)

        expect { described_class.new(data: data) }.not_to raise_error
      end

      it 'accepts null user_id' do
        data = valid_data.merge(user_id: nil)

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

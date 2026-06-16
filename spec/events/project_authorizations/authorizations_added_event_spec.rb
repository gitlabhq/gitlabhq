# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/project_authorizations/authorizations_added_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe ProjectAuthorizations::AuthorizationsAddedEvent, feature_category: :permissions do
  it_behaves_like 'an event with schema',
    valid_data: { user_ids: [1, 2] },
    missing_required: %i[user_ids],
    invalid_types: {
      user_ids: 'not_an_array',
      project_id: 'not_an_integer',
      project_ids: 'not_an_array'
    }

  describe '#schema' do
    let(:valid_data) { { user_ids: [1, 2] } }

    context 'with valid optional fields' do
      it 'accepts project_id' do
        data = valid_data.merge(project_id: 1)

        expect { described_class.new(data: data) }.not_to raise_error
      end

      it 'accepts project_ids' do
        data = valid_data.merge(project_ids: [1, 2])

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

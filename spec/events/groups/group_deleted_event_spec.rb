# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/groups/group_deleted_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Groups::GroupDeletedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: { group_id: 1, root_namespace_id: 2 },
    missing_required: %i[group_id root_namespace_id],
    invalid_types: { group_id: 'not_an_integer', root_namespace_id: 'not_an_integer' }

  describe '#schema' do
    context 'with valid optional parent_namespace_id' do
      it 'accepts an integer' do
        data = { group_id: 1, root_namespace_id: 2, parent_namespace_id: 3 }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

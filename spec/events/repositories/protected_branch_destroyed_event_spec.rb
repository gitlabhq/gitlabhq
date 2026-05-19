# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/repositories/protected_branch_destroyed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Repositories::ProtectedBranchDestroyedEvent, feature_category: :source_code_management do
  it_behaves_like 'an event with schema',
    valid_data: { parent_id: 1, parent_type: 'project' },
    missing_required: %i[parent_id parent_type],
    invalid_types: { parent_id: 'not_an_integer', parent_type: 'invalid' }

  describe '#schema' do
    context 'with valid parent_type values' do
      it 'accepts group' do
        data = { parent_id: 1, parent_type: 'group' }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/repositories/protected_branch_created_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Repositories::ProtectedBranchCreatedEvent, feature_category: :source_code_management do
  it_behaves_like 'an event with schema',
    valid_data: { protected_branch_id: 1, parent_id: 2, parent_type: 'project' },
    missing_required: %i[protected_branch_id parent_id parent_type],
    invalid_types: { protected_branch_id: 'not_an_integer', parent_type: 'invalid' }

  describe '#schema' do
    context 'with valid parent_type values' do
      it 'accepts group' do
        data = { protected_branch_id: 1, parent_id: 2, parent_type: 'group' }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

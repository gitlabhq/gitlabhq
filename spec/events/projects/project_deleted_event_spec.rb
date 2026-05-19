# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/projects/project_deleted_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Projects::ProjectDeletedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1, namespace_id: 2 },
    missing_required: %i[project_id namespace_id],
    invalid_types: { project_id: 'not_an_integer' }

  describe '#schema' do
    context 'with valid optional root_namespace_id' do
      it 'accepts an integer' do
        data = { project_id: 1, namespace_id: 2, root_namespace_id: 3 }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

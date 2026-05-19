# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/projects/project_features_changed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Projects::ProjectFeaturesChangedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3, features: ['pages_access_level'] },
    missing_required: %i[project_id namespace_id root_namespace_id features],
    invalid_types: { project_id: 'not_an_integer', features: 'not_an_array' }

  describe '#schema' do
    context 'with empty features array' do
      it 'accepts an empty array (no minItems constraint)' do
        data = { project_id: 1, namespace_id: 2, root_namespace_id: 3, features: [] }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

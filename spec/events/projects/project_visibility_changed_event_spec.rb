# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/projects/project_visibility_changed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Projects::ProjectVisibilityChangedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3, visibility_level: 20 },
    missing_required: %i[project_id namespace_id root_namespace_id visibility_level],
    invalid_types: { visibility_level: 'public' }
end

# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/projects/project_path_changed_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Projects::ProjectPathChangedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: {
      project_id: 1,
      namespace_id: 2,
      root_namespace_id: 3,
      old_path: 'old/project',
      new_path: 'new/project'
    },
    missing_required: %i[project_id namespace_id root_namespace_id old_path new_path],
    invalid_types: { old_path: 123 }
end

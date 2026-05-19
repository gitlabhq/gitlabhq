# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../app/events/namespaces/groups/group_archived_event'
require_relative '../../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Namespaces::Groups::GroupArchivedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: { group_id: 1, root_namespace_id: 2 },
    missing_required: %i[group_id root_namespace_id],
    invalid_types: { group_id: 'not_an_integer', root_namespace_id: 'not_an_integer' }
end

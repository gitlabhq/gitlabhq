# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/groups/group_transfered_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Groups::GroupTransferedEvent, feature_category: :groups_and_projects do
  it_behaves_like 'an event with schema',
    valid_data: { group_id: 1, old_root_namespace_id: 2, new_root_namespace_id: 3 },
    missing_required: %i[group_id old_root_namespace_id new_root_namespace_id],
    invalid_types: {
      group_id: 'not_an_integer',
      old_root_namespace_id: 'not_an_integer',
      new_root_namespace_id: 'not_an_integer'
    }
end

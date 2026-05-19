# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/repositories/repository_created_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Repositories::RepositoryCreatedEvent, feature_category: :source_code_management do
  it_behaves_like 'an event with schema',
    valid_data: { container_id: 1, container_type: 'Project' },
    missing_required: %i[container_id container_type],
    invalid_types: { container_id: 'not_an_integer', container_type: 123 }
end

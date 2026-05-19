# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/repositories/keep_around_refs_created_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Repositories::KeepAroundRefsCreatedEvent, feature_category: :source_code_management do
  it_behaves_like 'an event with schema',
    valid_data: {},
    missing_required: [],
    invalid_types: { project_id: 'not_an_integer' }

  describe '#schema' do
    context 'with valid optional project_id' do
      it 'accepts an integer' do
        expect { described_class.new(data: { project_id: 1 }) }.not_to raise_error
      end
    end
  end
end

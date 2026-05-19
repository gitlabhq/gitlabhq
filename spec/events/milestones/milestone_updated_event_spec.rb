# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../app/events/milestones/milestone_updated_event'
require_relative '../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Milestones::MilestoneUpdatedEvent, feature_category: :team_planning do
  it_behaves_like 'an event with schema',
    valid_data: { id: 1 },
    missing_required: %i[id],
    invalid_types: { id: 'not_an_integer', updated_attributes: [123] }

  describe '#schema' do
    let(:valid_data) { { id: 1 } }

    context 'with valid optional fields' do
      it 'accepts group_id and project_id' do
        data = valid_data.merge(group_id: 2, project_id: 3)

        expect { described_class.new(data: data) }.not_to raise_error
      end

      it 'accepts updated_attributes string array' do
        data = valid_data.merge(updated_attributes: %w[title due_date])

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end

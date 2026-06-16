# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../app/events/work_items/created_event'
require_relative '../../support/shared_examples/events/cloud_event_with_schema_shared_examples'
require_relative '../../support/shared_examples/events/work_item_base_event_shared_examples'

RSpec.describe WorkItems::CreatedEvent, feature_category: :code_suggestions do
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item) }

  describe '.build' do
    let(:event) do
      described_class.build(work_item: work_item, current_user: user)
    end

    it_behaves_like 'a work item base event'

    it 'sets event_type to :created' do
      expect(event.event_type).to eq(:created)
    end
  end

  it_behaves_like 'a cloud event with schema',
    valid_data: {
      work_item_id: 1,
      work_item_iid: 10,
      namespace_id: 100,
      project_id: 200,
      work_item_type: 'issue',
      confidential: false
    },
    missing_required: %i[work_item_id work_item_iid namespace_id project_id work_item_type confidential],
    invalid_types: {
      work_item_id: 'not_an_integer',
      work_item_iid: 'not_an_integer',
      namespace_id: 'not_an_integer',
      project_id: 'not_an_integer',
      work_item_type: 123,
      confidential: 'not_a_boolean'
    }
end

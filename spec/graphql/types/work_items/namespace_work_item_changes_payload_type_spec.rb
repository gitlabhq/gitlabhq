# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::NamespaceWorkItemChangesPayloadType, feature_category: :planning_views do
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('NamespaceWorkItemChangesPayload') }

  it 'has the expected fields' do
    expect(described_class).to have_graphql_fields(:action, :work_item_id)
  end

  describe '#work_item_id' do
    let_it_be(:work_item) { create(:work_item) }

    let(:object) { { work_item_id: work_item.id, action: :created } }

    it 'returns the work item global id' do
      expect(resolve_field(:work_item_id, object).to_s).to eq(work_item.to_global_id.to_s)
    end
  end
end

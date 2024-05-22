# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::WorkItems::ClosingMergeRequestType, feature_category: :team_planning do
  specify { expect(described_class.graphql_name).to eq('WorkItemClosingMergeRequest') }

  it 'exposes the expected fields' do
    expected_fields = %i[id from_mr_description merge_request]

    expect(described_class).to have_graphql_fields(expected_fields).at_least
  end
end

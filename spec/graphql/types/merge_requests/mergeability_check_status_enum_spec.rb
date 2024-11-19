# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::MergeabilityCheckStatusEnum, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeabilityCheckStatus') }

  it 'exposes all the existing mergeability check statuses' do
    expect(described_class.values.keys).to contain_exactly(
      *%w[SUCCESS CHECKING FAILED INACTIVE WARNING]
    )
  end
end

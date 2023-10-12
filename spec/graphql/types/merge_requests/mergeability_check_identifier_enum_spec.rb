# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::MergeabilityCheckIdentifierEnum, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeabilityCheckIdentifier') }

  it 'exposes all the existing mergeability check identifiers' do
    expect(described_class.values.keys).to contain_exactly(
      *MergeRequest.all_mergeability_checks.map { |check_class| check_class.identifier.to_s.upcase }
    )
  end
end

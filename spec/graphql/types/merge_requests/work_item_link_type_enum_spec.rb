# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::WorkItemLinkTypeEnum, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeRequestWorkItemLinkType') }

  it 'exposes all the existing link types' do
    expect(described_class.values.keys).to contain_exactly('CLOSES', 'MENTIONED')
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::WorkItemRelationType, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeRequestWorkItemRelation') }

  specify { expect(described_class).to require_graphql_authorizations(:read_merge_request_closing_issue) }

  it 'exposes the expected fields' do
    expected_fields = %i[id linkType fromMrDescription workItem]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'id' do
    subject { described_class.fields['id'] }

    it { is_expected.to have_non_null_graphql_type(::Types::GlobalIDType[::MergeRequestsClosingIssues]) }
  end

  describe 'link_type' do
    subject { described_class.fields['linkType'] }

    it { is_expected.to have_non_null_graphql_type(Types::MergeRequests::WorkItemLinkTypeEnum) }
  end

  describe 'work_item' do
    subject { described_class.fields['workItem'] }

    it { is_expected.to have_graphql_type(Types::WorkItemType) }
  end
end

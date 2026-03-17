# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::LinkedWorkItemType, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeRequestLinkedWorkItem') }

  it 'exposes the expected fields' do
    expected_fields = %i[linkType workItem externalIssue]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'work_item' do
    subject { described_class.fields['workItem'] }

    it { is_expected.to have_graphql_type(Types::WorkItemType) }
  end

  describe 'external_issue' do
    subject { described_class.fields['externalIssue'] }

    it { is_expected.to have_graphql_type(Types::MergeRequests::ExternalIssueType) }
  end

  describe 'link_type' do
    subject { described_class.fields['linkType'] }

    it { is_expected.to have_non_null_graphql_type(Types::MergeRequests::WorkItemLinkTypeEnum) }
  end
end

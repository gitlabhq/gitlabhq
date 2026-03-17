# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::ExternalIssueType, feature_category: :code_review_workflow do
  specify { expect(described_class.graphql_name).to eq('MergeRequestExternalIssue') }
  specify { expect(described_class).to require_graphql_authorizations(:read_issue) }

  it 'exposes the expected fields' do
    expected_fields = %i[reference title web_url]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'reference' do
    subject { described_class.fields['reference'] }

    it { is_expected.to have_non_null_graphql_type(GraphQL::Types::String) }
  end

  describe 'title' do
    subject { described_class.fields['title'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::String) }
  end

  describe 'webUrl' do
    subject { described_class.fields['webUrl'] }

    it { is_expected.to have_graphql_type(GraphQL::Types::String) }
  end
end

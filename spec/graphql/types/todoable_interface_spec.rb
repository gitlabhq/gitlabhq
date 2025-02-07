# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::TodoableInterface, feature_category: :notifications do
  include GraphqlHelpers

  it 'exposes the expected fields' do
    expected_fields = %i[
      web_url name
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    it 'knows the correct type for objects' do
      expect(described_class.resolve_type(build(:work_item), {})).to eq(Types::WorkItemType)
      expect(described_class.resolve_type(build(:issue), {})).to eq(Types::IssueType)
      expect(described_class.resolve_type(build(:merge_request), {})).to eq(Types::MergeRequestType)
      expect(described_class.resolve_type(build(:design), {})).to eq(Types::DesignManagement::DesignType)
      expect(described_class.resolve_type(build(:alert_management_alert), {})).to eq(Types::AlertManagement::AlertType)
      expect(described_class.resolve_type(build(:commit), {})).to eq(Types::Repositories::CommitType)
      expect(described_class.resolve_type(build(:project), {})).to eq(Types::ProjectType)
      expect(described_class.resolve_type(build(:group), {})).to eq(Types::GroupType)
      expect(described_class.resolve_type(build(:key), {})).to eq(Types::KeyType)
      expect(described_class.resolve_type(build(:wiki_page_meta), {})).to eq(Types::Wikis::WikiPageType)
      expect(described_class.resolve_type(build(:user), {})).to eq(Types::UserType)
    end

    it 'raises an error for an unknown type' do
      pipeline = build(:ci_pipeline)

      expect { described_class.resolve_type(pipeline, {}) }.to raise_error("Unknown GraphQL type for #{pipeline}")
    end
  end
end

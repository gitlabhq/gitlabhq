# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::TodoableInterface do
  it 'exposes the expected fields' do
    expected_fields = %i[
      web_url
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    it 'knows the correct type for objects' do
      expect(described_class.resolve_type(build(:issue), {})).to eq(Types::IssueType)
      expect(described_class.resolve_type(build(:merge_request), {})).to eq(Types::MergeRequestType)
      expect(described_class.resolve_type(build(:design), {})).to eq(Types::DesignManagement::DesignType)
      expect(described_class.resolve_type(build(:alert_management_alert), {})).to eq(Types::AlertManagement::AlertType)
      expect(described_class.resolve_type(build(:commit), {})).to eq(Types::CommitType)
    end

    it 'raises an error for an unknown type' do
      project = build(:project)

      expect { described_class.resolve_type(project, {}) }.to raise_error("Unknown GraphQL type for #{project}")
    end
  end
end

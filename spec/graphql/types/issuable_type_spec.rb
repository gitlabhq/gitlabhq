# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Issuable'] do
  it 'returns possible types' do
    expect(described_class.possible_types).to include(Types::IssueType, Types::MergeRequestType, Types::WorkItemType)
  end

  describe '.resolve_type' do
    it 'resolves issues' do
      expect(described_class.resolve_type(build(:issue), {})).to eq(Types::IssueType)
    end

    it 'resolves merge requests' do
      expect(described_class.resolve_type(build(:merge_request), {})).to eq(Types::MergeRequestType)
    end

    it 'resolves work items' do
      expect(described_class.resolve_type(build(:work_item), {})).to eq(Types::WorkItemType)
    end

    it 'raises an error for invalid types' do
      expect { described_class.resolve_type(build(:user), {}) }.to raise_error 'Unsupported issuable type'
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['RecentlyViewedItemUnion'], feature_category: :user_profile do
  it 'resolves Issue to IssueType' do
    expect(described_class.resolve_type(build(:issue), {})).to eq(Types::IssueType)
  end

  it 'resolves MergeRequest to MergeRequestType' do
    expect(described_class.resolve_type(build(:merge_request), {})).to eq(Types::MergeRequestType)
  end

  it 'raises error for unknown type' do
    expect { described_class.resolve_type(Object.new, {}) }.to raise_error(/Unexpected RecentlyViewedItem type/)
  end
end

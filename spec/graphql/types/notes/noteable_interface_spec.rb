# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Notes::NoteableInterface do
  it 'exposes the expected fields' do
    expected_fields = %i[
      discussions
      notes
      commenters
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe ".resolve_type" do
    it 'knows the correct type for objects' do
      expect(described_class.resolve_type(build(:issue), {})).to eq(Types::IssueType)
      expect(described_class.resolve_type(build(:merge_request), {})).to eq(Types::MergeRequestType)
      expect(described_class.resolve_type(build(:design), {})).to eq(Types::DesignManagement::DesignType)
      expect(described_class.resolve_type(build(:alert_management_alert), {})).to eq(Types::AlertManagement::AlertType)
      expect(described_class.resolve_type(build(:wiki_page_meta), {})).to eq(Types::Wikis::WikiPageType)
    end
  end
end

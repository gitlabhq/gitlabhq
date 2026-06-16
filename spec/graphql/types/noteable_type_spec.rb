# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NoteableType'], feature_category: :team_planning do
  it 'returns the expected possible types' do
    # `include` rather than `match_array`: EE prepends further noteables
    # (vulnerabilities, epics, compliance violations) to the union.
    expect(described_class.possible_types).to include(
      Types::IssueType,
      Types::MergeRequestType,
      Types::SnippetType,
      Types::DesignManagement::DesignType,
      Types::AlertManagement::AlertType,
      Types::Wikis::WikiPageType,
      Types::Repositories::CommitType
    )
  end

  describe '.resolve_type' do
    it 'resolves each supported noteable to its type', :aggregate_failures do
      expect(described_class.resolve_type(build_stubbed(:issue), {})).to eq(Types::IssueType)
      expect(described_class.resolve_type(build_stubbed(:merge_request), {})).to eq(Types::MergeRequestType)
      expect(described_class.resolve_type(build_stubbed(:project_snippet), {})).to eq(Types::SnippetType)
      expect(described_class.resolve_type(build_stubbed(:design), {})).to eq(Types::DesignManagement::DesignType)
      expect(described_class.resolve_type(build_stubbed(:alert_management_alert), {})).to eq(Types::AlertManagement::AlertType)
      expect(described_class.resolve_type(build_stubbed(:wiki_page_meta), {})).to eq(Types::Wikis::WikiPageType)
      # `Commit` is a PORO (not ActiveRecord), so it is built rather than stubbed.
      expect(described_class.resolve_type(build(:commit), {})).to eq(Types::Repositories::CommitType)
    end

    it 'raises for an unsupported type' do
      expect { described_class.resolve_type(build_stubbed(:user), {}) }
        .to raise_error(/Unknown GraphQL type/)
    end
  end

  describe '.resolvable?' do
    it 'returns true for a noteable the union can resolve', :aggregate_failures do
      expect(described_class.resolvable?(build_stubbed(:issue))).to be(true)
      expect(described_class.resolvable?(build_stubbed(:wiki_page_meta))).to be(true)
      expect(described_class.resolvable?(build(:commit))).to be(true)
    end

    it 'returns false for a noteable the union cannot resolve' do
      # `resolve_type` raises for an unmapped type; `resolvable?` swallows that so
      # callers (e.g. `Discussion#noteable`) can render the field as null instead
      # of failing the whole request with an Internal server error.
      expect(described_class.resolvable?(build_stubbed(:user))).to be(false)
    end
  end
end

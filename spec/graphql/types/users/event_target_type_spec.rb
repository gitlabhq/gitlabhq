# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Users::EventTargetType, feature_category: :user_profile do
  it 'returns possible types' do
    expect(described_class.possible_types).to include(Types::IssueType, Types::MilestoneType,
      Types::MergeRequestType, Types::ProjectType,
      Types::SnippetType, Types::UserType, Types::Wikis::WikiPageType,
      Types::DesignManagement::DesignType, Types::Notes::NoteType)
  end

  describe '.resolve_type' do
    using RSpec::Parameterized::TableSyntax

    where(:factory, :graphql_type) do
      :issue           | Types::IssueType
      :milestone       | Types::MilestoneType
      :merge_request   | Types::MergeRequestType
      :note            | Types::Notes::NoteType
      :project         | Types::ProjectType
      :project_snippet | Types::SnippetType
      :user            | Types::UserType
      :wiki_page_meta  | Types::Wikis::WikiPageType
      :design          | Types::DesignManagement::DesignType
    end

    with_them do
      it 'correctly maps type in object to GraphQL type' do
        expect(described_class.resolve_type(build(factory), {})).to eq(graphql_type)
      end
    end

    it 'raises an error if the type is not supported' do
      expect do
        described_class.resolve_type(build(:group), {})
      end.to raise_error(RuntimeError, /Unsupported event target type/)
    end
  end
end

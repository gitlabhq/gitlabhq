# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Release'] do
  it { expect(described_class).to require_graphql_authorizations(:read_release) }

  it 'has the expected fields' do
    expected_fields = %w[
      tag_name tag_path
      description description_html
      name milestones evidences author commit
      assets links
      created_at released_at upcoming_release
      historical_release
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'assets field' do
    subject { described_class.fields['assets'] }

    it { is_expected.to have_graphql_type(Types::ReleaseAssetsType) }
  end

  describe 'links field' do
    subject { described_class.fields['links'] }

    it { is_expected.to have_graphql_type(Types::ReleaseLinksType) }
  end

  describe 'milestones field' do
    subject { described_class.fields['milestones'] }

    it { is_expected.to have_graphql_type(Types::MilestoneType.connection_type) }
  end

  describe 'evidences field' do
    subject { described_class.fields['evidences'] }

    it { is_expected.to have_graphql_type(Types::EvidenceType.connection_type) }
  end

  describe 'author field' do
    subject { described_class.fields['author'] }

    it { is_expected.to have_graphql_type(Types::UserType) }
  end

  describe 'commit field' do
    subject { described_class.fields['commit'] }

    it { is_expected.to have_graphql_type(Types::Repositories::CommitType) }
  end
end

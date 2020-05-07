# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Release'] do
  it { expect(described_class).to require_graphql_authorizations(:read_release) }

  it 'has the expected fields' do
    expected_fields = %w[
      tag_name tag_path
      description description_html
      name evidence_sha milestones author commit
      created_at released_at
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'milestones field' do
    subject { described_class.fields['milestones'] }

    it { is_expected.to have_graphql_type(Types::MilestoneType.connection_type) }
  end

  describe 'author field' do
    subject { described_class.fields['author'] }

    it { is_expected.to have_graphql_type(Types::UserType) }
  end

  describe 'commit field' do
    subject { described_class.fields['commit'] }

    it { is_expected.to have_graphql_type(Types::CommitType) }
    it { is_expected.to require_graphql_authorizations(:reporter_access) }
  end
end

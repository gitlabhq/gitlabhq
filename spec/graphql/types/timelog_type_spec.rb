# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Timelog'] do
  let(:fields) { %i[spent_at time_spent user issue merge_request note] }

  it { expect(described_class.graphql_name).to eq('Timelog') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_issue) }

  describe 'user field' do
    subject { described_class.fields['user'] }

    it 'returns user' do
      is_expected.to have_non_null_graphql_type(Types::UserType)
    end
  end

  describe 'issue field' do
    subject { described_class.fields['issue'] }

    it 'returns issue' do
      is_expected.to have_graphql_type(Types::IssueType)
    end
  end

  describe 'merge_request field' do
    subject { described_class.fields['mergeRequest'] }

    it 'returns merge_request' do
      is_expected.to have_graphql_type(Types::MergeRequestType)
    end
  end

  describe 'note field' do
    subject { described_class.fields['note'] }

    it 'returns note' do
      is_expected.to have_graphql_type(Types::Notes::NoteType)
    end
  end
end

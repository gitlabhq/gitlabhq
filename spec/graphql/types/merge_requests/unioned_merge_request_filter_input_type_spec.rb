# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MergeRequests::UnionedMergeRequestFilterInputType, feature_category: :code_review_workflow do
  it 'has the correct graphql name' do
    expect(described_class.graphql_name).to eq('UnionedMergeRequestFilterInput')
  end

  describe 'arguments' do
    subject(:arguments) { described_class.arguments }

    it 'defines assignee_usernames argument' do
      expect(arguments).to include('assigneeUsernames')
    end

    describe 'assignee_usernames argument' do
      let(:argument) { subject['assigneeUsernames'] }

      it 'is not required' do
        expect(argument.type.non_null?).to be false
      end

      it 'is an array of strings' do
        expect(argument.type).to be_a(GraphQL::Schema::List)
      end

      it 'has the correct description' do
        expect(argument.description).to eq('Filters MRs that are assigned to at least one of the given users.')
      end
    end
  end
end

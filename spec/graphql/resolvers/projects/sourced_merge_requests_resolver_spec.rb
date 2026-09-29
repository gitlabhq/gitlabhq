# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::SourcedMergeRequestsResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::MergeRequestType.connection_type)
  end

  it 'declares the expected arguments' do
    expect(described_class.arguments.keys).to contain_exactly('sourceBranches', 'state')
  end

  it 'requires the sourceBranches argument' do
    expect(described_class.arguments['sourceBranches'].type).to be_non_null
  end
end

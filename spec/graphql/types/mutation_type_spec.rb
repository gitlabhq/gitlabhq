# frozen_string_literal: true

require 'spec_helper'

describe Types::MutationType do
  it 'is expected to have the MergeRequestSetWip' do
    expect(described_class).to have_graphql_mutation(Mutations::MergeRequests::SetWip)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MutationType do
  it 'is expected to have the MergeRequestSetDraft' do
    expect(described_class).to have_graphql_mutation(Mutations::MergeRequests::SetDraft)
  end

  def get_field(name)
    described_class.fields[GraphqlHelpers.fieldnamerize(name)]
  end
end

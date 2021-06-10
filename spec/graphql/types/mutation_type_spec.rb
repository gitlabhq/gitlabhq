# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::MutationType do
  it 'is expected to have the deprecated MergeRequestSetWip' do
    field = get_field('MergeRequestSetWip')

    expect(field).to be_present
    expect(field.deprecation_reason).to be_present
    expect(field.resolver).to eq(Mutations::MergeRequests::SetWip)
  end

  it 'is expected to have the MergeRequestSetDraft' do
    expect(described_class).to have_graphql_mutation(Mutations::MergeRequests::SetDraft)
  end

  def get_field(name)
    described_class.fields[GraphqlHelpers.fieldnamerize(name)]
  end
end

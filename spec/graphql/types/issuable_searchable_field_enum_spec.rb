# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::IssuableSearchableFieldEnum do
  specify { expect(described_class.graphql_name).to eq('IssuableSearchableField') }

  it 'exposes all the issuable searchable fields' do
    expect(described_class.values.keys).to contain_exactly(
      *Issuable::SEARCHABLE_FIELDS.map(&:upcase)
    )
  end
end

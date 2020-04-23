# frozen_string_literal: true

require 'spec_helper'

describe Types::IssuableSortEnum do
  it { expect(described_class.graphql_name).to eq('IssuableSort') }

  it 'exposes all the existing issuable sort values' do
    expect(described_class.values.keys).to include(*%w[PRIORITY_ASC PRIORITY_DESC])
  end
end

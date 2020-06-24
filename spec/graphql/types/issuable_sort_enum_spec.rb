# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::IssuableSortEnum do
  specify { expect(described_class.graphql_name).to eq('IssuableSort') }

  it 'exposes all the existing issuable sort values' do
    expect(described_class.values.keys).to include(
      *%w[PRIORITY_ASC PRIORITY_DESC
          LABEL_PRIORITY_ASC LABEL_PRIORITY_DESC
          MILESTONE_DUE_ASC MILESTONE_DUE_DESC]
    )
  end
end

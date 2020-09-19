# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestSort'] do
  specify { expect(described_class.graphql_name).to eq('MergeRequestSort') }

  it_behaves_like 'common sort values'

  it 'exposes all the existing issue sort values' do
    expect(described_class.values.keys).to include(
      *%w[MERGED_AT_ASC MERGED_AT_DESC]
    )
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::RecentFailuresType do
  specify { expect(described_class.graphql_name).to eq('RecentFailures') }

  it 'contains attributes related to a recent failure history for a test case' do
    expected_fields = %w[
      count base_branch
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::TestCaseStatusEnum do
  specify { expect(described_class.graphql_name).to eq('TestCaseStatus') }

  it 'exposes all test case status types' do
    expect(described_class.values.keys).to eq(
      ::Gitlab::Ci::Reports::TestCase::STATUS_TYPES
    )
  end
end

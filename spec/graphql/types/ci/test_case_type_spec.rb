# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::TestCaseType do
  specify { expect(described_class.graphql_name).to eq('TestCase') }

  it 'contains attributes related to a pipeline test case' do
    expected_fields = %w[
      name status classname file attachment_url execution_time stack_trace system_output recent_failures
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end

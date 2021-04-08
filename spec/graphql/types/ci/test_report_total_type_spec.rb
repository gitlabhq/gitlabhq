# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::TestReportTotalType do
  specify { expect(described_class.graphql_name).to eq('TestReportTotal') }

  it 'contains attributes related to a pipeline test report summary' do
    expected_fields = %w[
      time count success failed skipped error suite_error
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end

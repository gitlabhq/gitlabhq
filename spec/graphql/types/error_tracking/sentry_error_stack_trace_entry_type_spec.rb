# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SentryErrorStackTraceEntry'] do
  specify { expect(described_class.graphql_name).to eq('SentryErrorStackTraceEntry') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      function
      col
      line
      file_name
      trace_context
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SentryErrorStackTrace'] do
  specify { expect(described_class.graphql_name).to eq('SentryErrorStackTrace') }

  specify { expect(described_class).to require_graphql_authorizations(:read_sentry_issue) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      issue_id
      date_received
      stack_trace_entries
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end

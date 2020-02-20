# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['SentryErrorStackTrace'] do
  it { expect(described_class.graphql_name).to eq('SentryErrorStackTrace') }

  it { expect(described_class).to require_graphql_authorizations(:read_sentry_issue) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      issue_id
      date_received
      stack_trace_entries
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end

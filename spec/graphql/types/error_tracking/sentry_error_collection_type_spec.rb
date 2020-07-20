# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SentryErrorCollection'] do
  specify { expect(described_class.graphql_name).to eq('SentryErrorCollection') }

  specify { expect(described_class).to require_graphql_authorizations(:read_sentry_issue) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      errors
      detailed_error
      external_url
      error_stack_trace
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'errors field' do
    subject { described_class.fields['errors'] }

    it 'returns errors' do
      aggregate_failures 'testing the correct types are returned' do
        is_expected.to have_graphql_type(Types::ErrorTracking::SentryErrorType.connection_type)
        is_expected.to have_graphql_extension(Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension)
        is_expected.to have_graphql_resolver(Resolvers::ErrorTracking::SentryErrorsResolver)
      end
    end
  end
end

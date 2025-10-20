# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WebhookEvent'], feature_category: :webhooks do
  include GraphqlHelpers

  let_it_be_with_reload(:web_hook_log) { create(:web_hook_log) }
  let_it_be(:current_user) { create(:user, maintainer_of: web_hook_log.web_hook.project) }

  specify { expect(described_class.graphql_name).to eq('WebhookEvent') }

  specify { expect(described_class).to require_graphql_authorizations(:read_web_hook) }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      trigger
      url
      requestHeaders
      requestData
      responseHeaders
      responseBody
      responseStatus
      executionDuration
      internalErrorMessage
      oversize
      createdAt
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  shared_examples 'a webhook event headers field' do |field|
    subject(:resolved_headers_field) { resolve_field(field, web_hook_log, current_user: current_user) }

    it 'converts a hash of HTTP headers and values to an array of hashes with standardized keys' do
      web_hook_log.update!(
        field => { 'Content-Type' => 'application/json', 'CustomHeader' => 'some custom header value 1' }
      )

      expected_headers_list = [
        { name: 'Content-Type', value: 'application/json' },
        { name: 'CustomHeader', value: 'some custom header value 1' }
      ]

      expect(resolved_headers_field).to match_array(expected_headers_list)
    end

    it 'resolves to empty array when no headers are present' do
      web_hook_log.update!(field => nil)

      expect(resolved_headers_field).to eq([])
    end
  end

  describe 'request_headers field' do
    it_behaves_like 'a webhook event headers field', :request_headers
  end

  describe 'response_headers field' do
    it_behaves_like 'a webhook event headers field', :response_headers
  end
end

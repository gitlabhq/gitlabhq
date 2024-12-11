# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'When a user filters Sentry errors by status', :js, :use_clean_rails_memory_store_caching, :sidekiq_inline,
  feature_category: :observability do
  include_context 'sentry error tracking context feature'

  let_it_be(:issues_response_body) { fixture_file('sentry/issues_sample_response.json') }
  let_it_be(:filtered_errors_by_status_response) { Gitlab::Json.parse(issues_response_body).filter { |error| error['status'] == 'ignored' }.to_json }

  let(:issues_api_url) { "#{sentry_api_urls.issues_url}?limit=20&query=is:unresolved" }
  let(:issues_api_url_filter) { "#{sentry_api_urls.issues_url}?limit=20&query=is:ignored" }
  let(:auth_token) { { 'Authorization' => 'Bearer access_token_123' } }
  let(:return_header) { { 'Content-Type' => 'application/json' } }

  before do
    stub_request(:get, issues_api_url).with(headers: auth_token)
      .to_return(status: 200, body: issues_response_body, headers: return_header)

    stub_request(:get, issues_api_url_filter).with(headers: auth_token)
    .to_return(status: 200, body: filtered_errors_by_status_response, headers: return_header)
  end

  it 'displays the results' do
    sign_in(project.first_owner)
    visit project_error_tracking_index_path(project)
    page.within(find('.gl-table')) do
      results = page.all('.table-row')
      expect(results.count).to be(3)
    end

    find('[data-testid="status-dropdown"] .dropdown-toggle').click
    find('.dropdown-item', text: 'Ignored').click

    page.within(find('.gl-table')) do
      results = page.all('.table-row')
      expect(results.count).to be(1)
      expect(results.first).to have_content(filtered_errors_by_status_response[0]['title'])
    end
  end
end

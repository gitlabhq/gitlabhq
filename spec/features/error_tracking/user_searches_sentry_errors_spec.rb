# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'When a user searches for Sentry errors', :js, :use_clean_rails_memory_store_caching, :sidekiq_inline do
  include_context 'sentry error tracking context feature'

  let_it_be(:issues_response_body) { fixture_file('sentry/issues_sample_response.json') }
  let_it_be(:error_search_response_body) { fixture_file('sentry/error_list_search_response.json') }

  let(:issues_api_url) { "#{sentry_api_urls.issues_url}?limit=20&query=is:unresolved" }
  let(:issues_api_url_search) { "#{sentry_api_urls.issues_url}?limit=20&query=is:unresolved%20NotFound" }

  before do
    stub_request(:get, issues_api_url).with(
      headers: { 'Authorization' => 'Bearer access_token_123' }
    ).to_return(status: 200, body: issues_response_body, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, issues_api_url_search).with(
      headers: { 'Authorization' => 'Bearer access_token_123', 'Content-Type' => 'application/json' }
    ).to_return(status: 200, body: error_search_response_body, headers: { 'Content-Type' => 'application/json' })
  end

  it 'displays the results' do
    sign_in(project.owner)
    visit project_error_tracking_index_path(project)

    page.within(find('.gl-table')) do
      results = page.all('.table-row')
      expect(results.count).to be(3)
    end

    find('.gl-form-input').set('NotFound').native.send_keys(:return)

    page.within(find('.gl-table')) do
      results = page.all('.table-row')
      expect(results.count).to be(1)
      expect(results.first).to have_content('NotFound')
    end
  end
end

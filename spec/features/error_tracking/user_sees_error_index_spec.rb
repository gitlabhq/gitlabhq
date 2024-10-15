# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'View error index page', :js, :use_clean_rails_memory_store_caching, :sidekiq_inline,
  feature_category: :observability do
  include_context 'sentry error tracking context feature'

  let_it_be(:issues_response_body) { fixture_file('sentry/issues_sample_response.json') }
  let_it_be(:issues_response) { Gitlab::Json.parse(issues_response_body) }

  let(:issues_api_url) { "#{sentry_api_urls.issues_url}?limit=20&query=is:unresolved" }

  before do
    stub_request(:get, issues_api_url).with(
      headers: { 'Authorization' => 'Bearer access_token_123' }
    ).to_return(status: 200, body: issues_response_body, headers: { 'Content-Type' => 'application/json' })
  end

  context 'with current user as project owner' do
    before do
      sign_in(project.first_owner)

      visit project_error_tracking_index_path(project)
    end

    it_behaves_like 'error tracking index page'
  end

  # A bug caused the detail link to be broken for all users but the project owner
  context 'with current user as project maintainer' do
    let_it_be(:user) { create(:user) }

    before do
      project.add_maintainer(user)
      sign_in(user)

      visit project_error_tracking_index_path(project)
    end

    it_behaves_like 'error tracking index page'
  end

  context 'with error tracking settings disabled' do
    before do
      project_error_tracking_settings.update!(enabled: false)
      sign_in(project.first_owner)

      visit project_error_tracking_index_path(project)
    end

    it 'renders call to action' do
      expect(page).to have_content('Monitor your errors directly in GitLab.')
    end
  end

  context 'with current user as project guest' do
    let_it_be(:user) { create(:user) }

    before do
      project.add_guest(user)
      sign_in(user)

      visit project_error_tracking_index_path(project)
    end

    it 'renders not found' do
      expect(page).to have_content('Page not found')
    end
  end
end

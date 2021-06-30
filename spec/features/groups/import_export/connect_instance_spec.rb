# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import/Export - Connect to another instance', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  before do
    gitlab_sign_in(user)

    visit new_group_path

    click_link 'Import group'
  end

  context 'when the user provides valid credentials' do
    it 'successfully connects to remote instance' do
      source_url = 'https://gitlab.com'
      pat = 'demo-pat'
      stub_path = 'stub-group'
      total = 37

      stub_request(:get, "%{url}/api/v4/groups?page=1&per_page=20&top_level_only=true&min_access_level=50&search=" % { url: source_url }).to_return(
        body: [{
          id: 2595438,
          web_url: 'https://gitlab.com/groups/auto-breakfast',
          name: 'Stub',
          path: stub_path,
          full_name: 'Stub',
          full_path: stub_path
        }].to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-Next-Page' => 2,
          'X-Page' => 1,
          'X-Per-Page' => 20,
          'X-Total' => total,
          'X-Total-Pages' => 2
        }
      )

      allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
        allow(client).to receive(:validate_instance_version!).and_return(true)
      end

      expect(page).to have_content 'Import groups from another instance of GitLab'
      expect(page).to have_content 'Not all related objects are migrated'

      fill_in :bulk_import_gitlab_url, with: source_url
      fill_in :bulk_import_gitlab_access_token, with: pat

      click_on 'Connect instance'

      expect(page).to have_content 'Showing 1-1 of %{total} groups from %{url}' % { url: source_url, total: total }
      expect(page).to have_content stub_path

      visit '/'

      wait_for_all_requests
    end
  end

  context 'when the user provides invalid url' do
    it 'reports an error' do
      source_url = 'invalid-url'
      pat = 'demo-pat'

      fill_in :bulk_import_gitlab_url, with: source_url
      fill_in :bulk_import_gitlab_access_token, with: pat

      click_on 'Connect instance'

      expect(page).to have_content 'Specified URL cannot be used'
    end
  end

  context 'when the user does not fill in source URL' do
    it 'reports an error' do
      pat = 'demo-pat'

      fill_in :bulk_import_gitlab_access_token, with: pat

      click_on 'Connect instance'

      expect(page).to have_content 'Please fill in GitLab source URL'
    end
  end

  context 'when the user does not fill in access token' do
    it 'reports an error' do
      source_url = 'https://gitlab.com'

      fill_in :bulk_import_gitlab_url, with: source_url

      click_on 'Connect instance'

      expect(page).to have_content 'Please fill in your personal access token'
    end
  end
end

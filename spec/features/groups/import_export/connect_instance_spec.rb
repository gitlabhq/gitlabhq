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

    find('#import-group-tab').click
  end

  context 'when the user provides valid credentials' do
    it 'successfully connects to remote instance' do
      source_url = 'https://gitlab.com'
      pat = 'demo-pat'

      expect(page).to have_content 'Import groups from another instance of GitLab'

      fill_in :bulk_import_gitlab_url, with: source_url
      fill_in :bulk_import_gitlab_access_token, with: pat

      click_on 'Connect instance'

      expect(page).to have_content 'Importing groups from %{url}' % { url: source_url }
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

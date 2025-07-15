# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Import/Export - Connect to another instance', :js, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, owners: user) }

  context 'when importing groups and projects by direct transfer is enabled' do
    before do
      stub_application_setting(bulk_import_enabled: true)

      open_import_group
    end

    context 'when the user provides valid credentials' do
      source_url = 'https://gitlab.com'

      include_context 'bulk imports requests context', source_url

      it 'successfully connects to remote instance' do
        pat = 'demo-pat'

        expect(page).to have_content 'Import groups by direct transfer'
        expect(page).to have_content 'Not all group items are migrated'

        fill_in :bulk_import_gitlab_url, with: source_url
        fill_in :bulk_import_gitlab_access_token, with: pat

        click_on 'Connect instance'

        expect(page).to have_content 'stub-group'

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

        expect(page).to have_content 'Enter the URL for the source instance'
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

  context 'when importing groups and projects by direct transfer is disabled' do
    before do
      stub_application_setting(bulk_import_enabled: false)
    end

    context 'when the override_bulk_import_disabled feature flag is disabled' do
      before do
        stub_feature_flags(override_bulk_import_disabled: false)

        open_import_group
      end

      it 'does not render direct transfer section' do
        expect(page).not_to have_content('Import groups by direct transfer')
        expect(page).not_to have_field('GitLab source instance base URL')
        expect(page).not_to have_field('Personal access token')
        expect(page).not_to have_button('Connect instance')
      end
    end

    context 'when the override_bulk_import_disabled feature flag is enabled' do
      before do
        stub_feature_flags(override_bulk_import_disabled: true)

        open_import_group
      end

      it 'renders direct transfer section with fields and button enabled' do
        expect(page).to have_content('Import groups by direct transfer')
        expect(page).to have_field('GitLab source instance base URL', disabled: false)
        expect(page).to have_field('Personal access token', disabled: false)
        expect(page).to have_button('Connect instance', disabled: false)
      end
    end
  end

  def open_import_group
    gitlab_sign_in(user)

    visit new_group_path

    click_link 'Import group'
  end
end

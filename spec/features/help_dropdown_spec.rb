# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Help Dropdown", :js, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  before do
    stub_application_setting(version_check_enabled: true)
  end

  shared_examples 'no version check badge' do
    it 'does not render version check badge' do
      within_testid('super-sidebar') do
        click_on 'Help'

        expect(page).not_to have_text('Your GitLab version')
        expect(page).not_to have_text("#{Gitlab.version_info.major}.#{Gitlab.version_info.minor}")
        expect(page).not_to have_selector('[data-testid="check-version-badge"]')
        expect(page).not_to have_text('Up to date')
      end
    end
  end

  shared_examples 'correct version check badge' do |ui_text, severity|
    context "when severity is #{severity}" do
      before do
        sign_in(admin)
        enable_admin_mode!(admin)

        allow_next_instance_of(VersionCheck) do |instance|
          allow(instance).to receive(:response).and_return({ "severity" => severity })
        end
        visit root_path
      end

      it 'renders correct version check badge variant' do
        within_testid('super-sidebar') do
          click_on 'Help'

          expect(page).to have_text('Your GitLab version')
          expect(page).to have_text("#{Gitlab.version_info.major}.#{Gitlab.version_info.minor}")

          within page.find_link(href: help_page_path('update/_index.md')) do
            expect(page).to have_selector(".badge-#{severity}", text: ui_text)
          end
        end
      end
    end
  end

  context 'when anonymous user' do
    before do
      visit user_path(user)
    end

    include_examples 'no version check badge'
  end

  context 'when logged in as non-admin' do
    before do
      sign_in(user)
      visit root_path
    end

    include_examples 'no version check badge'
  end

  context 'when logged in as admin' do
    include_examples 'correct version check badge', 'Up to date', 'success'
    include_examples 'correct version check badge', 'Update available', 'warning'
    include_examples 'correct version check badge', 'Update ASAP', 'danger'
  end
end

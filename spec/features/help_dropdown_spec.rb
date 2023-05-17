# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Help Dropdown", :js, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  before do
    stub_application_setting(version_check_enabled: true)
  end

  context 'when logged in as non-admin' do
    before do
      sign_in(user)
      visit root_path
    end

    it 'does not render version data' do
      page.within '.header-help' do
        find('.header-help-dropdown-toggle').click

        expect(page).not_to have_text('Your GitLab Version')
        expect(page).not_to have_text("#{Gitlab.version_info.major}.#{Gitlab.version_info.minor}")
        expect(page).not_to have_selector('.version-check-badge')
        expect(page).not_to have_text('Up to date')
      end
    end
  end

  context 'when logged in as admin' do
    before do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    describe 'does render version data' do
      where(:response, :ui_text) do
        [
          [{ "severity" => "success" }, 'Up to date'],
          [{ "severity" => "warning" }, 'Update available'],
          [{ "severity" => "danger" }, 'Update ASAP']
        ]
      end

      with_them do
        before do
          allow_next_instance_of(VersionCheck) do |instance|
            allow(instance).to receive(:response).and_return(response)
          end
          visit root_path
        end

        it 'renders correct version badge variant',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/369850' do
          page.within '.header-help' do
            find('.header-help-dropdown-toggle').click

            expect(page).to have_text('Your GitLab Version')
            expect(page).to have_text("#{Gitlab.version_info.major}.#{Gitlab.version_info.minor}")
            expect(page).to have_selector('.version-check-badge')
            expect(page).to have_selector(
              'a[data-testid="gitlab-version-container"][href="/help/update/index"]'
            )
            expect(page).to have_selector('.version-check-badge[href="/help/update/index"]')
            expect(page).to have_text(ui_text)
          end
        end
      end
    end
  end
end

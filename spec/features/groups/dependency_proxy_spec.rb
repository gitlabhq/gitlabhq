# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Dependency Proxy', feature_category: :virtual_registry do
  let(:owner) { create(:user) }
  let(:reporter) { create(:user) }
  let(:group) { create(:group) }
  let(:path) { group_dependency_proxy_path(group) }
  let(:settings_path) { group_settings_packages_and_registries_path(group) }

  before do
    group.add_owner(owner)
    group.add_reporter(reporter)

    enable_feature
  end

  describe 'feature settings' do
    context 'when not logged in' do
      it 'renders 404 page' do
        visit path

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end

    context 'feature is available', :js do
      context 'when logged in as group owner' do
        before do
          sign_in(owner)
        end

        it 'sidebar menu is open' do
          visit path

          expect(page).to have_active_navigation('Operate')
          expect(page).to have_active_sub_navigation('Dependency Proxy')
        end

        it 'toggles defaults to enabled' do
          visit path

          expect(page).to have_css('[data-testid="proxy-url"]')
        end

        it 'shows the proxy URL' do
          visit path

          expect(find('input[data-testid="proxy-url"]').value).to have_content('/dependency_proxy/containers')
        end

        it 'has link to settings' do
          visit path

          expect(page).to have_link s_('DependencyProxy|Configure in settings')
        end

        it 'renders 404 page after disabling the feature' do
          visit settings_path

          proxy_toggle = find_by_testid('dependency-proxy-setting-toggle')
          proxy_toggle_button = proxy_toggle.find('button')

          expect(proxy_toggle).to have_css("button.is-checked")

          proxy_toggle_button.click

          expect(page).to have_content _('Settings saved successfully.')
          expect(proxy_toggle).not_to have_css("button.is-checked")

          visit path

          expect(page).to have_content s_('404|404: Page not found')
        end
      end

      context 'when logged in as group reporter' do
        before do
          sign_in(reporter)
          visit path
        end

        it 'does not show the feature toggle but shows the proxy URL' do
          expect(find('input[data-testid="proxy-url"]').value).to have_content('/dependency_proxy/containers')
        end

        it 'does not have link to settings' do
          expect(page).not_to have_link s_('DependencyProxy|Configure in settings')
        end
      end
    end

    context 'feature is not avaible' do
      before do
        sign_in(owner)
      end

      context 'feature is disabled globally' do
        it 'renders 404 page' do
          disable_feature

          visit path

          expect(page).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  def enable_feature
    stub_config(dependency_proxy: { enabled: true })
  end

  def disable_feature
    stub_config(dependency_proxy: { enabled: false })
  end
end

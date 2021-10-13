# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Dependency Proxy' do
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
    context 'when not logged in and feature disabled' do
      it 'does not show the feature settings' do
        group.create_dependency_proxy_setting(enabled: false)

        visit path

        expect(page).not_to have_css('.js-dependency-proxy-url')
      end
    end

    context 'feature is available', :js do
      context 'when logged in as group owner' do
        before do
          sign_in(owner)
        end

        it 'sidebar menu is open' do
          visit path

          sidebar = find('.nav-sidebar')
          expect(sidebar).to have_link _('Dependency Proxy')
        end

        it 'toggles defaults to enabled' do
          visit path

          expect(page).to have_css('.js-dependency-proxy-url')
        end

        it 'shows the proxy URL' do
          visit path

          expect(find('.js-dependency-proxy-url').value).to have_content('/dependency_proxy/containers')
        end

        it 'hides the proxy URL when feature is disabled' do
          visit settings_path
          wait_for_requests

          click_button 'Enable Proxy'

          expect(page).to have_button 'Enable Proxy', class: '!is-checked'

          visit path

          expect(page).not_to have_css('.js-dependency-proxy-url')
        end
      end

      context 'when logged in as group reporter' do
        before do
          sign_in(reporter)
          visit path
        end

        it 'does not show the feature toggle but shows the proxy URL' do
          expect(find('.js-dependency-proxy-url').value).to have_content('/dependency_proxy/containers')
        end
      end
    end

    context 'feature is not avaible' do
      before do
        sign_in(owner)
      end

      context 'feature flag is disabled' do
        before do
          stub_feature_flags(dependency_proxy_for_private_groups: false)
        end

        context 'group is private' do
          let(:group) { create(:group, :private) }

          it 'informs user that feature is only available for public groups' do
            visit path

            expect(page).to have_content('Dependency proxy feature is limited to public groups for now.')
          end
        end
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

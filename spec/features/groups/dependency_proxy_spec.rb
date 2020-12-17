# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Dependency Proxy' do
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:group) { create(:group) }
  let(:path) { group_dependency_proxy_path(group) }

  before do
    group.add_developer(developer)
    group.add_reporter(reporter)

    enable_feature
  end

  describe 'feature settings' do
    context 'when not logged in and feature disabled' do
      it 'does not show the feature settings' do
        group.create_dependency_proxy_setting(enabled: false)

        visit path

        expect(page).not_to have_css('.js-dependency-proxy-toggle-area')
        expect(page).not_to have_css('.js-dependency-proxy-url')
      end
    end

    context 'feature is available', :js do
      context 'when logged in as group developer' do
        before do
          sign_in(developer)
          visit path
        end

        it 'sidebar menu is open' do
          sidebar = find('.nav-sidebar')
          expect(sidebar).to have_link _('Dependency Proxy')
        end

        it 'toggles defaults to enabled' do
          page.within('.js-dependency-proxy-toggle-area') do
            expect(find('.js-project-feature-toggle-input', visible: false).value).to eq('true')
          end
        end

        it 'shows the proxy URL' do
          page.within('.edit_dependency_proxy_group_setting') do
            expect(find('.js-dependency-proxy-url').value).to have_content('/dependency_proxy/containers')
          end
        end

        it 'hides the proxy URL when feature is disabled' do
          page.within('.edit_dependency_proxy_group_setting') do
            find('.js-project-feature-toggle').click
          end

          expect(page).not_to have_css('.js-dependency-proxy-url')
          expect(find('.js-project-feature-toggle-input', visible: false).value).to eq('false')
        end
      end

      context 'when logged in as group reporter' do
        before do
          sign_in(reporter)
          visit path
        end

        it 'does not show the feature toggle but shows the proxy URL' do
          expect(page).not_to have_css('.js-dependency-proxy-toggle-area')
          expect(find('.js-dependency-proxy-url').value).to have_content('/dependency_proxy/containers')
        end
      end
    end

    context 'feature is not avaible' do
      before do
        sign_in(developer)
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

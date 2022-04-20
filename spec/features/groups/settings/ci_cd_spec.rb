# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group CI/CD settings' do
  include WaitForRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group) }

  before_all do
    group.add_owner(user)
  end

  before do
    sign_in(user)
  end

  describe 'Runners section' do
    let(:shared_runners_toggle) { page.find('[data-testid="enable-runners-toggle"]') }

    context 'with runner_list_group_view_vue_ui enabled' do
      before do
        visit group_settings_ci_cd_path(group)
      end

      it 'displays the new group runners view banner' do
        expect(page).to have_content(s_('Runners|New group runners view'))
        expect(page).to have_link(href: group_runners_path(group))
      end

      it 'has "Enable shared runners for this group" toggle', :js do
        expect(shared_runners_toggle).to have_content(_('Enable shared runners for this group'))
      end
    end

    context 'with runner_list_group_view_vue_ui disabled' do
      before do
        stub_feature_flags(runner_list_group_view_vue_ui: false)

        visit group_settings_ci_cd_path(group)
      end

      it 'does not display the new group runners view banner' do
        expect(page).not_to have_content(s_('Runners|New group runners view'))
        expect(page).not_to have_link(href: group_runners_path(group))
      end

      it 'has "Enable shared runners for this group" toggle', :js do
        expect(shared_runners_toggle).to have_content(_('Enable shared runners for this group'))
      end

      context 'with runners registration token' do
        let!(:token) { group.runners_token }

        before do
          visit group_settings_ci_cd_path(group)
        end

        it 'displays the registration token' do
          expect(page.find('#registration_token')).to have_content(token)
        end

        describe 'reload registration token' do
          let(:page_token) { find('#registration_token').text }

          before do
            click_button 'Reset registration token'
          end

          it 'changes the registration token' do
            expect(page_token).not_to eq token
          end
        end
      end
    end
  end

  describe 'Auto DevOps form' do
    before do
      stub_application_setting(auto_devops_enabled: true)
    end

    context 'as owner first visiting group settings' do
      it 'sees instance enabled badge' do
        visit group_settings_ci_cd_path(group)

        page.within '#auto-devops-settings' do
          expect(page).to have_content('instance enabled')
        end
      end
    end

    context 'when Auto DevOps group has been enabled' do
      it 'sees group enabled badge' do
        group.update!(auto_devops_enabled: true)

        visit group_settings_ci_cd_path(group)

        page.within '#auto-devops-settings' do
          expect(page).to have_content('group enabled')
        end
      end
    end

    context 'when Auto DevOps group has been disabled' do
      it 'does not see a badge' do
        group.update!(auto_devops_enabled: false)

        visit group_settings_ci_cd_path(group)

        page.within '#auto-devops-settings' do
          expect(page).not_to have_content('instance enabled')
          expect(page).not_to have_content('group enabled')
        end
      end
    end
  end
end

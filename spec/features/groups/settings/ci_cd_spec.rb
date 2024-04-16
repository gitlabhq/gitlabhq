# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group CI/CD settings', feature_category: :continuous_integration do
  include WaitForRequests

  let_it_be(:user) { create(:user) }
  let_it_be(:group, reload: true) { create(:group, owners: user) }

  before do
    sign_in(user)
  end

  describe 'Runners section' do
    let(:shared_runners_toggle) { find_by_testid('shared-runners-toggle') }

    before do
      visit group_settings_ci_cd_path(group)
    end

    it 'has "Enable instance runners for this group" toggle', :js do
      expect(shared_runners_toggle).to have_content(_('Enable instance runners for this group'))
    end

    it 'clicks on toggle to enable setting', :js do
      expect(group.shared_runners_setting).to be(Namespace::SR_ENABLED)

      shared_runners_toggle.find('button').click
      wait_for_requests

      group.reload
      expect(group.shared_runners_setting).to be(Namespace::SR_DISABLED_AND_UNOVERRIDABLE)
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

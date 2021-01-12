# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group CI/CD settings' do
  include WaitForRequests

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'runners registration token' do
    let!(:token) { group.runners_token }

    before do
      visit group_settings_ci_cd_path(group)
    end

    it 'has a registration token' do
      expect(page.find('#registration_token')).to have_content(token)
    end

    describe 'reload registration token' do
      let(:page_token) { find('#registration_token').text }

      before do
        click_button 'Reset registration token'
      end

      it 'changes registration token' do
        expect(page_token).not_to eq token
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

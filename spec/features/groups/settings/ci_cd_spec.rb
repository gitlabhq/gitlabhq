# frozen_string_literal: true

require 'spec_helper'

describe 'Group CI/CD settings' do
  include WaitForRequests

  let(:user) {create(:user)}
  let(:group) {create(:group)}

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
        click_button 'Reset runners registration token'
      end

      it 'changes registration token' do
        expect(page_token).not_to eq token
      end
    end
  end
end

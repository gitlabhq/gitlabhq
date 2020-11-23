# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin disables 2FA for a user' do
  it 'successfully', :js do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    user = create(:user, :two_factor)

    edit_user(user)
    page.within('.two-factor-status') do
      accept_confirm { click_link 'Disable' }
    end

    page.within('.two-factor-status') do
      expect(page).to have_content 'Disabled'
      expect(page).not_to have_button 'Disable'
    end
  end

  it 'for a user without 2FA enabled' do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    user = create(:user)

    edit_user(user)

    page.within('.two-factor-status') do
      expect(page).not_to have_button 'Disable'
    end
  end

  def edit_user(user)
    visit admin_user_path(user)
  end
end

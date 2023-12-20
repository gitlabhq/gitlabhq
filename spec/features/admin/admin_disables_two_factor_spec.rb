# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin disables 2FA for a user', feature_category: :system_access do
  include Spec::Support::Helpers::ModalHelpers

  it 'successfully', :js do
    admin = create(:admin)
    sign_in(admin)
    enable_admin_mode!(admin)
    user = create(:user, :two_factor)

    edit_user(user)
    page.within('.two-factor-status') do
      click_link 'Disable'
    end

    accept_gl_confirm(button_text: 'Disable')

    page.within('.two-factor-status') do
      expect(page).to have_content 'Disabled'
      expect(page).not_to have_button 'Disable'
    end
  end

  it 'for a user without 2FA enabled' do
    admin = create(:admin)
    sign_in(admin)
    enable_admin_mode!(admin)
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

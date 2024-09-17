# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registrations', :with_current_organization, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  context 'when the user visits the registration page when already signed in', :clean_gitlab_redis_sessions do
    before do
      sign_in(user)
    end

    it 'does not show an "You are already signed in" error message' do
      visit new_user_registration_path

      wait_for_requests

      expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
    end
  end

  context 'when the user registers having an invitation', :js do
    let(:group) { create(:group, :private) }
    let(:new_user) { build(:user) }

    before do
      stub_application_setting_enum('email_confirmation_setting', 'soft')
      stub_application_setting(require_admin_approval_after_user_signup: false)
    end

    it 'becomes a member after confirmation' do
      create(:group_member, :invited, :developer, source: group, invite_email: new_user.email)

      visit new_user_registration_path
      fill_in_sign_up_form(new_user)

      confirm_email(new_user)
      visit polymorphic_path(group)

      expect(page).to have_content(group.name)
      expect(page).not_to have_content('Page not found')
    end
  end
end

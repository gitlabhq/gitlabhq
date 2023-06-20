# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registrations', feature_category: :system_access do
  context 'when the user visits the registration page when already signed in', :clean_gitlab_redis_sessions do
    let_it_be(:current_user) { create(:user) }

    before do
      sign_in(current_user)
    end

    it 'does not show an "You are already signed in" error message' do
      visit new_user_registration_path

      wait_for_requests

      expect(page).not_to have_content(I18n.t('devise.failure.already_authenticated'))
    end
  end
end

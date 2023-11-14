# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Logout/Sign out', :js, feature_category: :system_access do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit root_path
  end

  it 'sign out redirects to sign in page' do
    gitlab_sign_out

    expect(page).to have_current_path new_user_session_path, ignore_query: true
  end

  it 'sign out does not show signed out flash notice' do
    gitlab_sign_out

    expect(page).not_to have_selector('[data-testid="alert-info"]')
  end

  context 'on a read-only instance' do
    before do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
    end

    it 'sign out redirects to sign in page' do
      gitlab_sign_out

      expect(page).to have_current_path new_user_session_path, ignore_query: true
    end
  end
end

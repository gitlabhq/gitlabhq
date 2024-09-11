# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Mode Logout', :js, feature_category: :system_access do
  include TermsHelper
  include UserLoginHelper

  let(:user) { create(:admin) }

  before do
    gitlab_sign_in(user)
    enable_admin_mode!(user, use_ui: true)
    visit admin_root_path
  end

  it 'disable removes admin mode and redirects to root page' do
    gitlab_disable_admin_mode

    expect(page).to have_current_path root_path, ignore_query: true

    find_by_testid('user-menu-toggle').click

    expect(page).to have_link(href: new_admin_session_path)
  end

  it 'disable shows flash notice' do
    gitlab_disable_admin_mode

    expect(page).to have_selector('[data-testid="alert-info"]', text: _('Admin mode disabled'))
  end

  context 'on a read-only instance' do
    before do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
    end

    it 'disable removes admin mode and redirects to root page' do
      gitlab_disable_admin_mode

      expect(page).to have_current_path root_path, ignore_query: true

      find_by_testid('user-menu-toggle').click

      expect(page).to have_link(href: new_admin_session_path)
    end
  end
end

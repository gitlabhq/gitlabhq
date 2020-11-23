# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Mode Logout', :js do
  include TermsHelper
  include UserLoginHelper

  let(:user) { create(:admin) }

  before do
    gitlab_sign_in(user)
    gitlab_enable_admin_mode_sign_in(user)
    visit admin_root_path
  end

  it 'disable removes admin mode and redirects to root page' do
    gitlab_disable_admin_mode

    expect(current_path).to eq root_path
    expect(page).to have_link(href: new_admin_session_path)
  end

  it 'disable shows flash notice' do
    gitlab_disable_admin_mode

    expect(page).to have_selector('.flash-notice')
  end

  context 'on a read-only instance' do
    before do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
    end

    it 'disable removes admin mode and redirects to root page' do
      gitlab_disable_admin_mode

      expect(current_path).to eq root_path
      expect(page).to have_link(href: new_admin_session_path)
    end
  end
end

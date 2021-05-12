# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Mode Logout', :js do
  include TermsHelper
  include UserLoginHelper

  let(:user) { create(:admin) }

  shared_examples 'combined_menu: feature flag examples' do
    before do
      gitlab_sign_in(user)
      gitlab_enable_admin_mode_sign_in(user)
      visit admin_root_path
    end

    it 'disable removes admin mode and redirects to root page' do
      pending_on_combined_menu_flag

      gitlab_disable_admin_mode

      expect(current_path).to eq root_path
      expect(page).to have_link(href: new_admin_session_path)
    end

    it 'disable shows flash notice' do
      pending_on_combined_menu_flag

      gitlab_disable_admin_mode

      expect(page).to have_selector('.flash-notice')
    end

    context 'on a read-only instance' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it 'disable removes admin mode and redirects to root page' do
        pending_on_combined_menu_flag

        gitlab_disable_admin_mode

        expect(current_path).to eq root_path
        expect(page).to have_link(href: new_admin_session_path)
      end
    end
  end

  context 'with combined_menu: feature flag on' do
    let(:needs_rewrite_for_combined_menu_flag_on) { true }

    before do
      stub_feature_flags(combined_menu: true)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  context 'with combined_menu feature flag off' do
    let(:needs_rewrite_for_combined_menu_flag_on) { false }

    before do
      stub_feature_flags(combined_menu: false)
    end

    it_behaves_like 'combined_menu: feature flag examples'
  end

  def pending_on_combined_menu_flag
    pending 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56587' if needs_rewrite_for_combined_menu_flag_on
  end
end

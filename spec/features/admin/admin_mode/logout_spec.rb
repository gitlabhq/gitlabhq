# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin mode logout', :js, feature_category: :system_access do
  include TermsHelper
  include UserLoginHelper

  let(:user) { create(:admin) }
  let(:current_organization) { user.organization }

  before do
    sign_in(user)
    enter_admin_mode(user)
  end

  context 'when leaving the admin mode' do
    it 'removes admin mode and redirects to root page' do
      leave_admin_mode

      expect(page).to have_current_path root_path, ignore_query: true

      find_by_testid('user-menu-toggle').click

      expect(page).to have_link(href: new_admin_session_path)
    end

    context 'on a read-only instance' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it 'removes admin mode and redirects to root page' do
        leave_admin_mode

        expect(page).to have_current_path root_path, ignore_query: true

        find_by_testid('user-menu-toggle').click

        expect(page).to have_link(href: new_admin_session_path)
      end
    end
  end
end

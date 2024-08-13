# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin mode', :js, feature_category: :shared do
  include MobileHelpers
  include StubENV

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  context 'application setting :admin_mode is enabled', :request_store do
    before do
      sign_in(admin)
    end

    context 'when not in admin mode' do
      it 'has no leave admin mode button' do
        visit new_admin_session_path
        open_user_menu

        expect(page).not_to have_link(href: destroy_admin_session_path)
      end

      it 'can open pages not in admin scope' do
        visit new_admin_session_path
        open_user_menu

        click_link('Edit profile')

        expect(page).to have_current_path(user_settings_profile_path)
      end

      it 'is necessary to provide credentials again before opening pages in admin scope' do
        visit general_admin_application_settings_path # admin logged out because not in admin_mode

        expect(page).to have_current_path(new_admin_session_path)
      end

      it 'can enter admin mode' do
        visit root_dashboard_path
        open_user_menu
        click_link 'Enter Admin Mode'

        fill_in 'user_password', with: admin.password

        click_button 'Enter admin mode'
        click_link 'Admin'

        expect(page).to have_current_path(admin_root_path)
      end

      context 'on a read-only instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'can enter admin mode' do
          visit new_admin_session_path

          fill_in 'user_password', with: admin.password

          click_button 'Enter admin mode'

          expect(page).to have_current_path(admin_root_path)
        end
      end
    end

    context 'when in admin_mode' do
      before do
        enable_admin_mode!(admin, use_ui: true)
      end

      it 'contains link to leave admin mode' do
        open_user_menu
        click_link('Leave Admin Mode', href: destroy_admin_session_path)
        expect(page).to have_text 'Admin mode disabled'
      end

      it 'can open pages not in admin scope' do
        open_user_menu

        click_link('Edit profile')

        expect(page).to have_current_path(user_settings_profile_path)
      end

      context 'sidebar' do
        it 'shows admin dashboard link' do
          visit root_dashboard_path

          within '#super-sidebar' do
            expect(page).to have_link('Admin')
          end
        end
      end

      context 'on a read-only instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'can leave admin mode' do
          gitlab_disable_admin_mode

          open_user_menu

          expect(page).to have_link(href: new_admin_session_path)
        end
      end
    end
  end

  context 'application setting :admin_mode is disabled' do
    before do
      stub_application_setting(admin_mode: false)
      sign_in(admin)
    end

    it 'shows no admin mode buttons in navbar' do
      visit admin_root_path
      open_user_menu

      expect(page).not_to have_link(href: new_admin_session_path)
      expect(page).not_to have_link(href: destroy_admin_session_path)
    end
  end

  def open_user_menu
    find_by_testid('user-menu-toggle').click
  end
end

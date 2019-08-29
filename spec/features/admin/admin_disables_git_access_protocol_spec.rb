# frozen_string_literal: true

require 'spec_helper'

describe 'Admin disables Git access protocol', :js do
  include StubENV
  include MobileHelpers

  let(:project) { create(:project, :empty_repo) }
  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  context 'with HTTP disabled' do
    before do
      disable_http_protocol
    end

    it 'shows only SSH url' do
      visit_project

      expect(page).to have_content("git clone #{project.ssh_url_to_repo}")

      find('.clone-dropdown-btn').click

      within('.git-clone-holder') do
        expect(page).to have_content('Clone with SSH')
        expect(page).not_to have_content('Clone with HTTP')
      end
    end

    context 'mobile component' do
      it 'shows only the SSH clone information' do
        resize_screen_xs
        visit_project
        find('.dropdown-toggle').click

        expect(page).to have_content('Copy SSH clone URL')
        expect(page).not_to have_content('Copy HTTP clone URL')
      end
    end
  end

  context 'with SSH disabled' do
    before do
      disable_ssh_protocol
    end

    it 'shows only HTTP url' do
      visit_project
      find('.clone-dropdown-btn').click

      expect(page).to have_content("git clone #{project.http_url_to_repo}")

      within('.git-clone-holder') do
        expect(page).to have_content('Clone with HTTP')
        expect(page).not_to have_content('Clone with SSH')
      end
    end

    context 'mobile component' do
      it 'shows only the HTTP clone information' do
        resize_screen_xs
        visit_project
        find('.dropdown-toggle').click

        expect(page).to have_content('Copy HTTP clone URL')
        expect(page).not_to have_content('Copy SSH clone URL')
      end
    end
  end

  context 'with nothing disabled' do
    before do
      create(:personal_key, user: admin)
    end

    it 'shows default SSH url and protocol selection dropdown' do
      visit_project

      expect(page).to have_content("git clone #{project.ssh_url_to_repo}")

      find('.clone-dropdown-btn').click

      within('.git-clone-holder') do
        expect(page).to have_content('Clone with SSH')
        expect(page).to have_content('Clone with HTTP')
      end
    end

    context 'mobile component' do
      it 'shows both SSH and HTTP clone information' do
        resize_screen_xs
        visit_project
        find('.dropdown-toggle').click

        expect(page).to have_content('Copy HTTP clone URL')
        expect(page).to have_content('Copy SSH clone URL')
      end
    end
  end

  def visit_project
    visit project_path(project)
  end

  def disable_http_protocol
    switch_git_protocol(2)
  end

  def disable_ssh_protocol
    switch_git_protocol(3)
  end

  def switch_git_protocol(value)
    visit admin_application_settings_path

    page.within('.as-visibility-access') do
      find('#application_setting_enabled_git_access_protocol').find(:xpath, "option[#{value}]").select_option
      click_on 'Save'
    end
  end
end

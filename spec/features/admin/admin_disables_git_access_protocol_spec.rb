require 'rails_helper'

feature 'Admin disables Git access protocol' do
  include StubENV

  let(:project) { create(:project, :empty_repo) }
  let(:admin) { create(:admin) }

  background do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  context 'with HTTP disabled' do
    background do
      disable_http_protocol
    end

    scenario 'shows only SSH url' do
      visit_project

      expect(page).to have_content("git clone #{project.ssh_url_to_repo}")
      expect(page).not_to have_selector('#clone-dropdown')
    end
  end

  context 'with SSH disabled' do
    background do
      disable_ssh_protocol
    end

    scenario 'shows only HTTP url' do
      visit_project

      expect(page).to have_content("git clone #{project.http_url_to_repo}")
      expect(page).not_to have_selector('#clone-dropdown')
    end
  end

  context 'with nothing disabled' do
    background do
      create(:personal_key, user: admin)
    end

    scenario 'shows default SSH url and protocol selection dropdown' do
      visit_project

      expect(page).to have_content("git clone #{project.ssh_url_to_repo}")
      expect(page).to have_selector('#clone-dropdown')
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

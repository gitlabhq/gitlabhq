require 'rails_helper'

feature 'Admin uses repository checks', feature: true do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
  end

  scenario 'to trigger a single check' do
    project = create(:empty_project)
    visit_admin_project_page(project)

    page.within('.repository-check') do
      click_button 'Trigger repository check'
    end

    expect(page).to have_content('Repository check was triggered')
  end

  scenario 'to see a single failed repository check' do
    project = create(:empty_project)
    project.update_columns(
      last_repository_check_failed: true,
      last_repository_check_at: Time.now
    )
    visit_admin_project_page(project)

    page.within('.alert') do
      expect(page.text).to match(/Last repository check \(.* ago\) failed/)
    end
  end

  scenario 'to clear all repository checks', js: true do
    visit admin_application_settings_path

    expect(RepositoryCheck::ClearWorker).to receive(:perform_async)

    click_link 'Clear all repository checks'

    expect(page).to have_content('Started asynchronous removal of all repository check states.')
  end

  def visit_admin_project_page(project)
    visit admin_project_path(project)
  end
end

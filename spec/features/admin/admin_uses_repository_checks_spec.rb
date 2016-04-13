require 'rails_helper'

feature 'Admin uses repository checks', feature: true do
  before do
    login_as :admin
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
    visit_admin_project_page(broken_project)

    page.within('.alert') do
      expect(page.text).to match(/Last repository check \(.* ago\) failed/)
    end
  end

  scenario 'to clear all repository checks', js: true do
    project = broken_project
    visit admin_application_settings_path

    click_link 'Clear all repository checks' # pop-up should be auto confirmed

    expect(project.reload.last_repository_check_failed).to eq(false)
  end

  def visit_admin_project_page(project)
    visit admin_namespace_project_path(project.namespace, project)
  end

  def broken_project
    project = create(:empty_project)
    project.update_columns(
      last_repository_check_failed: true,
      last_repository_check_at: Time.now,
    )
    project
  end
end

require 'spec_helper'
require 'rails_helper'

describe "Admin Projects", feature: true  do
  before do
    @project = create(:project)
    login_as :admin
  end

  describe "GET /admin/projects" do
    before do
      visit admin_namespaces_projects_path
    end

    it "should be ok" do
      expect(current_path).to eq(admin_namespaces_projects_path)
    end

    it "should have projects list" do
      expect(page).to have_content(@project.name)
    end
  end

  describe "GET /admin/projects/:id" do
    before do
      visit admin_namespaces_projects_path
      click_link "#{@project.name}"
    end

    it "should have project info" do
      expect(page).to have_content(@project.path)
      expect(page).to have_content(@project.name)
    end
  end

  feature 'repository checks' do
    scenario 'trigger repository check' do
      visit_admin_project_page

      page.within('.repository-check') do
        click_button 'Trigger repository check'
      end

      expect(page).to have_content('Repository check was triggered')
    end

    scenario 'see failed repository check' do
      @project.update_column(:last_repository_check_failed, true)
      visit_admin_project_page

      expect(page).to have_content('Last repository check failed')
    end

    scenario 'clear repository checks', js: true do
      @project.update_column(:last_repository_check_failed, true)
      visit admin_namespaces_projects_path

      page.within('.repository-check-states') do
        click_link 'Clear all' # pop-up should be auto confirmed
      end

      expect(@project.reload.last_repository_check_failed).to eq(false)
    end
  end

  def visit_admin_project_page
    visit admin_namespace_project_path(@project.namespace, @project)
  end
end

require 'spec_helper'

describe "Admin::Projects", feature: true  do
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
end

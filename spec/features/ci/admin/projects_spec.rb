require 'spec_helper'

describe "Admin Projects" do
  let(:project) { FactoryGirl.create :project }

  before do
    skip_admin_auth
    login_as :user
  end

  describe "GET /admin/projects" do
    before do
      project
      visit admin_projects_path
    end

    it { page.should have_content "Projects" }
  end
end

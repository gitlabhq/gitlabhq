require 'spec_helper'

describe "Admin Projects" do
  let(:project) { FactoryGirl.create :ci_project }

  before do
    skip_ci_admin_auth
    login_as :user
  end

  describe "GET /admin/projects" do
    before do
      project
      visit ci_admin_projects_path
    end

    it { expect(page).to have_content "Projects" }
  end
end

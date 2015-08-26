require 'spec_helper'

describe "Admin Builds" do
  let(:project) { FactoryGirl.create :project }
  let(:commit) { FactoryGirl.create :commit, project: project }
  let(:build) { FactoryGirl.create :build, commit: commit }

  before do
    skip_admin_auth
    login_as :user
  end

  describe "GET /admin/builds" do
    before do
      build
      visit admin_builds_path
    end

    it { page.should have_content "All builds" }
    it { page.should have_content build.short_sha }
  end

  describe "Tabs" do
    it "shows all builds" do
      build = FactoryGirl.create :build, commit: commit, status: "pending"
      build1 = FactoryGirl.create :build, commit: commit, status: "running"
      build2 = FactoryGirl.create :build, commit: commit, status: "success"
      build3 = FactoryGirl.create :build, commit: commit, status: "failed"

      visit admin_builds_path

      page.all(".build-link").size.should == 4
    end

    it "shows pending builds" do
      build = FactoryGirl.create :build, commit: commit, status: "pending"
      build1 = FactoryGirl.create :build, commit: commit, status: "running"
      build2 = FactoryGirl.create :build, commit: commit, status: "success"
      build3 = FactoryGirl.create :build, commit: commit, status: "failed"

      visit admin_builds_path

      within ".nav.nav-tabs" do
        click_on "Pending"
      end

      page.find(".build-link").should have_content(build.id)
      page.find(".build-link").should_not have_content(build1.id)
      page.find(".build-link").should_not have_content(build2.id)
      page.find(".build-link").should_not have_content(build3.id)
    end

    it "shows running builds" do
      build = FactoryGirl.create :build, commit: commit, status: "pending"
      build1 = FactoryGirl.create :build, commit: commit, status: "running"
      build2 = FactoryGirl.create :build, commit: commit, status: "success"
      build3 = FactoryGirl.create :build, commit: commit, status: "failed"

      visit admin_builds_path

      within ".nav.nav-tabs" do
        click_on "Running"
      end

      page.find(".build-link").should have_content(build1.id)
      page.find(".build-link").should_not have_content(build.id)
      page.find(".build-link").should_not have_content(build2.id)
      page.find(".build-link").should_not have_content(build3.id)
    end
  end
end

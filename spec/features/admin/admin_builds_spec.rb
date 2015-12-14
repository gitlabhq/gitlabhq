require 'spec_helper'

describe "Admin Builds" do
  let(:commit) { FactoryGirl.create :ci_commit }
  let(:build) { FactoryGirl.create :ci_build, commit: commit }

  before do
    login_as :admin
  end

  describe "GET /admin/builds" do
    before do
      build
      visit admin_builds_path
    end

    it { expect(page).to have_content "Running" }
    it { expect(page).to have_content build.short_sha }
  end

  describe "Tabs" do
    it "shows all builds" do
      FactoryGirl.create :ci_build, commit: commit, status: "pending"
      FactoryGirl.create :ci_build, commit: commit, status: "running"
      FactoryGirl.create :ci_build, commit: commit, status: "success"
      FactoryGirl.create :ci_build, commit: commit, status: "failed"

      visit admin_builds_path

      within ".center-top-menu" do
        click_on "All"
      end

      expect(page.all(".build-link").size).to eq(4)
    end

    it "shows finished builds" do
      build = FactoryGirl.create :ci_build, commit: commit, status: "pending"
      build1 = FactoryGirl.create :ci_build, commit: commit, status: "running"
      build2 = FactoryGirl.create :ci_build, commit: commit, status: "success"

      visit admin_builds_path

      within ".center-top-menu" do
        click_on "Finished"
      end

      expect(page.find(".build-link")).not_to have_content(build.id)
      expect(page.find(".build-link")).not_to have_content(build1.id)
      expect(page.find(".build-link")).to have_content(build2.id)
    end

    it "shows running builds" do
      build = FactoryGirl.create :ci_build, commit: commit, status: "pending"
      build2 = FactoryGirl.create :ci_build, commit: commit, status: "success"
      build3 = FactoryGirl.create :ci_build, commit: commit, status: "failed"

      visit admin_builds_path

      within ".center-top-menu" do
        click_on "Running"
      end

      expect(page.find(".build-link")).to have_content(build.id)
      expect(page.find(".build-link")).not_to have_content(build2.id)
      expect(page.find(".build-link")).not_to have_content(build3.id)
    end
  end
end

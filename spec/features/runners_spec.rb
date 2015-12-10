require 'spec_helper'

describe "Runners" do
  include GitlabRoutingHelper

  let(:user) { create(:user) }
  before { login_as(user) }

  describe "specific runners" do
    before do
      @project = FactoryGirl.create :ci_project
      @project.gl_project.team << [user, :master]

      @project2 = FactoryGirl.create :ci_project
      @project2.gl_project.team << [user, :master]

      @project3 = FactoryGirl.create :ci_project
      @project3.gl_project.team << [user, :developer]

      @shared_runner = FactoryGirl.create :ci_shared_runner
      @specific_runner = FactoryGirl.create :ci_specific_runner
      @specific_runner2 = FactoryGirl.create :ci_specific_runner
      @specific_runner3 = FactoryGirl.create :ci_specific_runner
      @project.runners << @specific_runner
      @project2.runners << @specific_runner2
      @project3.runners << @specific_runner3

      visit runners_path(@project.gl_project)
    end

    before do
      expect(page).to_not have_content(@specific_runner3.display_name)
      expect(page).to_not have_content(@specific_runner3.display_name)
    end

    it "places runners in right places" do
      expect(page.find(".available-specific-runners")).to have_content(@specific_runner2.display_name)
      expect(page.find(".activated-specific-runners")).to have_content(@specific_runner.display_name)
      expect(page.find(".available-shared-runners")).to have_content(@shared_runner.display_name)
    end

    it "enables specific runner for project" do
      within ".available-specific-runners" do
        click_on "Enable for this project"
      end

      expect(page.find(".activated-specific-runners")).to have_content(@specific_runner2.display_name)
    end

    it "disables specific runner for project" do
      @project2.runners << @specific_runner
      visit runners_path(@project.gl_project)

      within ".activated-specific-runners" do
        click_on "Disable for this project"
      end

      expect(page.find(".available-specific-runners")).to have_content(@specific_runner.display_name)
    end

    it "removes specific runner for project if this is last project for that runners" do
      within ".activated-specific-runners" do
        click_on "Remove runner"
      end

      expect(Ci::Runner.exists?(id: @specific_runner)).to be_falsey
    end
  end

  describe "shared runners" do
    before do
      @project = FactoryGirl.create :ci_project
      @project.gl_project.team << [user, :master]
      visit runners_path(@project.gl_project)
    end

    it "enables shared runners" do
      click_on "Enable shared runners"
      expect(@project.reload.shared_runners_enabled).to be_truthy
    end
  end

  describe "show page" do
    before do
      @project = FactoryGirl.create :ci_project
      @project.gl_project.team << [user, :master]
      @specific_runner = FactoryGirl.create :ci_specific_runner
      @project.runners << @specific_runner
    end

    it "shows runner information" do
      visit runners_path(@project.gl_project)
      click_on @specific_runner.short_sha
      expect(page).to have_content(@specific_runner.platform)
    end
  end
end

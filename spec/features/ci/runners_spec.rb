require 'spec_helper'

describe "Runners" do
  let(:user)    { create(:user) }

  before do
    login_as(user)
  end

  describe "specific runners" do
    before do
      @project = FactoryGirl.create :ci_project
      @project.gl_project.team << [user, :master]

      @project2 = FactoryGirl.create :ci_project
      @project2.gl_project.team << [user, :master]

      @shared_runner = FactoryGirl.create :ci_shared_runner
      @specific_runner = FactoryGirl.create :ci_specific_runner
      @specific_runner2 = FactoryGirl.create :ci_specific_runner
      @project.runners << @specific_runner
      @project2.runners << @specific_runner2
    end

    it "places runners in right places" do
      visit ci_project_runners_path(@project)
      expect(page.find(".available-specific-runners")).to have_content(@specific_runner2.display_name)
      expect(page.find(".activated-specific-runners")).to have_content(@specific_runner.display_name)
      expect(page.find(".available-shared-runners")).to have_content(@shared_runner.display_name)
    end

    it "enables specific runner for project" do
      visit ci_project_runners_path(@project)

      within ".available-specific-runners" do
        click_on "Enable for this project"
      end

      expect(page.find(".activated-specific-runners")).to have_content(@specific_runner2.display_name)
    end

    it "disables specific runner for project" do
      @project2.runners << @specific_runner

      visit ci_project_runners_path(@project)

      within ".activated-specific-runners" do
        click_on "Disable for this project"
      end

      expect(page.find(".available-specific-runners")).to have_content(@specific_runner.display_name)
    end

    it "removes specific runner for project if this is last project for that runners" do
      visit ci_project_runners_path(@project)

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
    end

    it "enables shared runners" do
      visit ci_project_runners_path(@project)

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
      visit ci_project_runners_path(@project)

      click_on @specific_runner.short_sha

      expect(page).to have_content(@specific_runner.platform)
    end
  end
end

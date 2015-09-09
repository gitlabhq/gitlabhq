require 'spec_helper'

describe "Runners" do
  before do
    login_as :user
  end

  describe "specific runners" do
    before do
      @project = FactoryGirl.create :project
      @project2 = FactoryGirl.create :project
      stub_js_gitlab_calls

      # all projects should be authorized for user
      Network.any_instance.stub(:projects).and_return([
        OpenStruct.new({id: @project.gitlab_id}),
        OpenStruct.new({id: @project2.gitlab_id})
      ])

      @shared_runner = FactoryGirl.create :shared_runner
      @specific_runner = FactoryGirl.create :specific_runner
      @specific_runner2 = FactoryGirl.create :specific_runner
      @project.runners << @specific_runner
      @project2.runners << @specific_runner2
    end

    it "places runners in right places" do
      visit project_runners_path(@project)
      page.find(".available-specific-runners").should have_content(@specific_runner2.display_name)
      page.find(".activated-specific-runners").should have_content(@specific_runner.display_name)
      page.find(".available-shared-runners").should have_content(@shared_runner.display_name)
    end

    it "enables specific runner for project" do
      visit project_runners_path(@project)

      within ".available-specific-runners" do
        click_on "Enable for this project"
      end

      page.find(".activated-specific-runners").should have_content(@specific_runner2.display_name)
    end

    it "disables specific runner for project" do
      @project2.runners << @specific_runner

      visit project_runners_path(@project)

      within ".activated-specific-runners" do
        click_on "Disable for this project"
      end

      page.find(".available-specific-runners").should have_content(@specific_runner.display_name)
    end

    it "removes specific runner for project if this is last project for that runners" do
      visit project_runners_path(@project)

      within ".activated-specific-runners" do
        click_on "Remove runner"
      end

      Runner.exists?(id: @specific_runner).should be_false
    end
  end

  describe "shared runners" do
    before do
      @project = FactoryGirl.create :project
      stub_js_gitlab_calls
    end

    it "enables shared runners" do
      visit project_runners_path(@project)

      click_on "Enable shared runners"

      @project.reload.shared_runners_enabled.should be_true
    end
  end

  describe "show page" do
    before do
      @project = FactoryGirl.create :project
      stub_js_gitlab_calls
      @specific_runner = FactoryGirl.create :specific_runner
      @project.runners << @specific_runner
    end

    it "shows runner information" do
      visit project_runners_path(@project)

      click_on @specific_runner.short_sha

      page.should have_content(@specific_runner.platform)
    end
  end
end

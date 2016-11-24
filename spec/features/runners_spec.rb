require 'spec_helper'

describe "Runners" do
  include GitlabRoutingHelper

  let(:user) { create(:user) }
  before { login_as(user) }

  describe "specific runners" do
    before do
      @project = FactoryGirl.create :empty_project, shared_runners_enabled: false
      @project.team << [user, :master]

      @project2 = FactoryGirl.create :empty_project
      @project2.team << [user, :master]

      @project3 = FactoryGirl.create :empty_project
      @project3.team << [user, :developer]

      @shared_runner = FactoryGirl.create :ci_runner, :shared
      @specific_runner = FactoryGirl.create :ci_runner
      @specific_runner2 = FactoryGirl.create :ci_runner
      @specific_runner3 = FactoryGirl.create :ci_runner
      @project.runners << @specific_runner
      @project2.runners << @specific_runner2
      @project3.runners << @specific_runner3

      visit runners_path(@project)
    end

    before do
      expect(page).not_to have_content(@specific_runner3.display_name)
      expect(page).not_to have_content(@specific_runner3.display_name)
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
      visit runners_path(@project)

      within ".activated-specific-runners" do
        click_on "Disable for this project"
      end

      expect(page.find(".available-specific-runners")).to have_content(@specific_runner.display_name)
    end

    it "removes specific runner for project if this is last project for that runners" do
      within ".activated-specific-runners" do
        click_on "Remove Runner"
      end

      expect(Ci::Runner.exists?(id: @specific_runner)).to be_falsey
    end
  end

  describe "shared runners" do
    before do
      @project = FactoryGirl.create :empty_project, shared_runners_enabled: false
      @project.team << [user, :master]
      visit runners_path(@project)
    end

    it "enables shared runners" do
      click_on "Enable shared Runners"
      expect(@project.reload.shared_runners_enabled).to be_truthy
    end
  end

  describe "shared runners description" do
    let(:shared_runners_text) { 'custom **shared** runners description' }
    let(:shared_runners_html) { 'custom shared runners description' }

    before do
      stub_application_setting(shared_runners_text: shared_runners_text)
      project = FactoryGirl.create :empty_project, shared_runners_enabled: false
      project.team << [user, :master]
      visit runners_path(project)
    end

    it "sees shared runners description" do
      expect(page.find(".shared-runners-description")).to have_content(shared_runners_html)
    end
  end

  describe "show page" do
    before do
      @project = FactoryGirl.create :empty_project
      @project.team << [user, :master]
      @specific_runner = FactoryGirl.create :ci_runner
      @project.runners << @specific_runner
    end

    it "shows runner information" do
      visit runners_path(@project)
      click_on @specific_runner.short_sha
      expect(page).to have_content(@specific_runner.platform)
    end
  end

  feature 'configuring runners ability to picking untagged jobs' do
    given(:project) { create(:empty_project) }
    given(:runner) { create(:ci_runner) }

    background do
      project.team << [user, :master]
      project.runners << runner
    end

    scenario 'user checks default configuration' do
      visit namespace_project_runner_path(project.namespace, project, runner)

      expect(page).to have_content 'Can run untagged jobs Yes'
    end

    context 'when runner has tags' do
      before { runner.update_attribute(:tag_list, ['tag']) }

      scenario 'user wants to prevent runner from running untagged job' do
        visit runners_path(project)
        page.within('.activated-specific-runners') do
          first('small > a').click
        end

        uncheck 'runner_run_untagged'
        click_button 'Save changes'

        expect(page).to have_content 'Can run untagged jobs No'
        expect(runner.reload.run_untagged?).to eq false
      end
    end
  end
end

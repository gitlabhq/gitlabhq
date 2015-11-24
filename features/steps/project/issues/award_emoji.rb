class Spinach::Features::AwardEmoji < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'I visit "Bugfix" issue page' do
    visit namespace_project_issue_path(@project.namespace, @project, @issue)
  end

  step 'I click to emoji-picker' do
    page.within ".awards-controls" do
      page.find(".add-award").click
    end
  end

  step 'I click to emoji in the picker' do
    page.within ".awards-menu" do
      page.first("img").click
    end
  end

  step 'I can remove it by clicking to icon' do
    page.within ".awards" do
      page.first(".award").click
      expect(page).to_not have_selector ".award"
    end
  end

  step 'I have award added' do
    page.within ".awards" do
      expect(page).to have_selector ".award"
      expect(page.find(".award .counter")).to have_content "1"
    end
  end

  step 'project "Shop" has issue "Bugfix"' do
    @project = Project.find_by(name: "Shop")
    @issue = create(:issue, title: "Bugfix", project: project)
  end
end

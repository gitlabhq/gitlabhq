class Spinach::Features::ProjectIssuesFilterLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'I should see "Bugfix1" in issues list' do
    page.within ".issues-list" do
      expect(page).to have_content "Bugfix1"
    end
  end

  step 'I should see "Bugfix2" in issues list' do
    page.within ".issues-list" do
      expect(page).to have_content "Bugfix2"
    end
  end

  step 'I should not see "Bugfix2" in issues list' do
    page.within ".issues-list" do
      expect(page).not_to have_content "Bugfix2"
    end
  end

  step 'I should not see "Feature1" in issues list' do
    page.within ".issues-list" do
      expect(page).not_to have_content "Feature1"
    end
  end

  step 'I click "dropdown close button"' do
    page.first('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
    sleep 2
  end

  step 'I click link "feature"' do
    page.within ".labels-filter" do
      click_link "feature"
    end
  end

  step 'project "Shop" has issue "Bugfix1" with labels: "bug", "feature"' do
    project = Project.find_by(name: "Shop")
    issue = create(:issue, title: "Bugfix1", project: project)
    issue.labels << project.labels.find_by(title: 'bug')
    issue.labels << project.labels.find_by(title: 'feature')
  end

  step 'project "Shop" has issue "Bugfix2" with labels: "bug", "enhancement"' do
    project = Project.find_by(name: "Shop")
    issue = create(:issue, title: "Bugfix2", project: project)
    issue.labels << project.labels.find_by(title: 'bug')
    issue.labels << project.labels.find_by(title: 'enhancement')
  end

  step 'project "Shop" has issue "Feature1" with labels: "feature"' do
    project = Project.find_by(name: "Shop")
    issue = create(:issue, title: "Feature1", project: project)
    issue.labels << project.labels.find_by(title: 'feature')
  end
end

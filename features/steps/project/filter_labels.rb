class ProjectFilterLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'I should see "bug" in labels filter' do
    within ".labels-filter" do
      page.should have_content "bug"
    end
  end

  step 'I should see "feature" in labels filter' do
    within ".labels-filter" do
      page.should have_content "feature"
    end
  end

  step 'I should see "enhancement" in labels filter' do
    within ".labels-filter" do
      page.should have_content "enhancement"
    end
  end

  step 'I should see "Bugfix1" in issues list' do
    within ".issues-list" do
      page.should have_content "Bugfix1"
    end
  end

  step 'I should see "Bugfix2" in issues list' do
    within ".issues-list" do
      page.should have_content "Bugfix2"
    end
  end

  step 'I should not see "Bugfix2" in issues list' do
    within ".issues-list" do
      page.should_not have_content "Bugfix2"
    end
  end

  step 'I should not see "Feature1" in issues list' do
    within ".issues-list" do
      page.should_not have_content "Feature1"
    end
  end

  step 'I click link "bug"' do
    within ".labels-filter" do
      click_link "bug"
    end
  end

  step 'I click link "feature"' do
    within ".labels-filter" do
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

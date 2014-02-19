class ProjectFilterLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I should see "bug" in labels filter' do
    within ".labels-filter" do
      page.should have_content "bug"
    end
  end

  And 'I should see "feature" in labels filter' do
    within ".labels-filter" do
      page.should have_content "feature"
    end
  end

  And 'I should see "enhancement" in labels filter' do
    within ".labels-filter" do
      page.should have_content "enhancement"
    end
  end

  Then 'I should see "Bugfix1" in issues list' do
    within ".issues-list" do
      page.should have_content "Bugfix1"
    end
  end

  And 'I should see "Bugfix2" in issues list' do
    within ".issues-list" do
      page.should have_content "Bugfix2"
    end
  end

  And 'I should not see "Bugfix2" in issues list' do
    within ".issues-list" do
      page.should_not have_content "Bugfix2"
    end
  end

  And 'I should not see "Feature1" in issues list' do
    within ".issues-list" do
      page.should_not have_content "Feature1"
    end
  end

  Given 'I click link "bug"' do
    click_link "bug"
  end

  Given 'I click link "feature"' do
    click_link "feature"
  end

  And 'project "Shop" has issue "Bugfix1" with tags: "bug", "feature"' do
    project = Project.find_by(name: "Shop")
    create(:issue, title: "Bugfix1", project: project, label_list: ['bug', 'feature'])
  end

  And 'project "Shop" has issue "Bugfix2" with tags: "bug", "enhancement"' do
    project = Project.find_by(name: "Shop")
    create(:issue, title: "Bugfix2", project: project, label_list: ['bug', 'enhancement'])
  end

  And 'project "Shop" has issue "Feature1" with tags: "feature"' do
    project = Project.find_by(name: "Shop")
    create(:issue, title: "Feature1", project: project, label_list: 'feature')
  end
end

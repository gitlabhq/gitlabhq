class ProjectLabels < Spinach::FeatureSteps
  Then 'I should see label "bug"' do
    within ".labels-table" do
      page.should have_content "bug"
    end
  end

  And 'I should see label "feature"' do
    within ".labels-table" do
      page.should have_content "feature"
    end
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'project "Shop" have issues tags: "bug", "feature"' do
    project = Project.find_by_name("Shop")
    ['bug', 'feature'].each do |label|
      Factory :issue, project: project, label_list: label
    end
  end

  Given 'I visit project "Shop" labels page' do
    visit project_labels_path(Project.find_by_name("Shop"))
  end
end

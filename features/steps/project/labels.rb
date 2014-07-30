class ProjectLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

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

  And 'project "Shop" have issues tags: "bug", "feature"' do
    project = Project.find_by(name: "Shop")
    label1 = create(:label, project: project, title: 'bug')
    label2 = create(:label, project: project, title: 'feature')
  end
end

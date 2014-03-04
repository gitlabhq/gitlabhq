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
    ['bug', 'feature'].each do |label|
      create(:issue, project: project, label_list: label)
    end
  end
end

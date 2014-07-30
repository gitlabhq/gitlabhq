class ProjectLabels < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I should see label "bug"' do
    within ".manage-labels-list" do
      page.should have_content "bug"
    end
  end

  And 'I should see label "feature"' do
    within ".manage-labels-list" do
      page.should have_content "feature"
    end
  end
end

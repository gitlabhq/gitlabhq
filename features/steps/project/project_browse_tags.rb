class ProjectBrowseTags < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I should see "Shop" all tags list' do
    page.should have_content "Tags"
    page.should have_content "v1.2.1"
  end
end

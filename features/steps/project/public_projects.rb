class PublicProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I should see the list of public projects' do
    page.should have_content "Public Projects"
  end

  step 'I should see a link to public snippets' do
    page.should have_content "Snippets"
  end
end

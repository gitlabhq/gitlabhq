class Spinach::Features::DashboardHelp < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedMarkdown

  step 'I visit the help page' do
    visit help_path
  end

  step 'I visit the "Rake Tasks" help page' do
    visit help_page_path("raketasks", "maintenance")
  end

  step 'I should see "Rake Tasks" page markdown rendered' do
    expect(page).to have_content "Gather information about GitLab and the system it runs on"
  end

  step 'Header "Rebuild project satellites" should have correct ids and links' do
    header_should_have_correct_id_and_link(2, 'Check GitLab configuration', 'check-gitlab-configuration', '.documentation')
  end
end

class Spinach::Features::Help < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedMarkdown

  step 'I visit the help page' do
    visit help_path
  end

  step 'I visit the "Rake Tasks" help page' do
    visit help_raketasks_path
  end

  step 'I should see "Rake Tasks" page markdown rendered' do
    page.should have_content "GitLab provides some specific rake tasks to enable special features or perform maintenance tasks"
  end

  step 'Header "Rebuild project satellites" should have correct ids and links' do
    header_should_have_correct_id_and_link(3, 'Rebuild project satellites', 'rebuild-project-satellites')
  end
end
